import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────
// Modèle produit alimentaire
// ─────────────────────────────────────────
class FoodProduct {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final double calories;      // kcal/100g
  final double sugars;        // g/100g
  final double carbohydrates; // g/100g
  final double fat;           // g/100g
  final double proteins;      // g/100g
  final String? nutriScore;   // A, B, C, D, E
  final int glycemicRisk;     // 0=faible, 1=moyen, 2=élevé
  final String glycemicLabel;
  final String glycemicAdvice;

  const FoodProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.calories,
    required this.sugars,
    required this.carbohydrates,
    required this.fat,
    required this.proteins,
    this.nutriScore,
    required this.glycemicRisk,
    required this.glycemicLabel,
    required this.glycemicAdvice,
  });
}

// ─────────────────────────────────────────
// Service OpenFoodFacts
// ─────────────────────────────────────────
class NutritionService {
  static const String _baseUrl = 'https://world.openfoodfacts.org';
  static const Duration _timeout = Duration(seconds: 10);

  // ── Recherche par code-barres
  static Future<FoodProduct?> searchByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v0/product/$barcode.json');
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) return null;

      return _parseProduct(data['product'] as Map<String, dynamic>, barcode);
    } catch (_) {
      return null;
    }
  }

  // ── Recherche par nom
  static Future<List<FoodProduct>> searchByName(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final uri = Uri.parse(
          '$_baseUrl/cgi/search.pl?search_terms=$encoded&search_simple=1&action=process&json=1&page_size=10');
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = (data['products'] as List<dynamic>?) ?? [];

      return products
          .map((p) => _parseProduct(p as Map<String, dynamic>,
              p['code']?.toString() ?? ''))
          .where((p) => p.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Parser les données brutes d'un produit
  static FoodProduct _parseProduct(
      Map<String, dynamic> p, String barcode) {
    final nutriments = (p['nutriments'] as Map<String, dynamic>?) ?? {};

    double _d(String key) {
      final v = nutriments[key];
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final name  = p['product_name']?.toString() ??
                  p['product_name_fr']?.toString() ?? '';
    final brand = p['brands']?.toString() ?? '';
    final image = p['image_front_url']?.toString() ??
                  p['image_url']?.toString() ?? '';

    final calories = _d('energy-kcal_100g');
    final sugars   = _d('sugars_100g');
    final carbs    = _d('carbohydrates_100g');
    final fat      = _d('fat_100g');
    final proteins = _d('proteins_100g');

    final rawNutriScore = p['nutriscore_grade']?.toString().toUpperCase() ??
                          p['nutrition_grade_fr']?.toString().toUpperCase();
    final nutriScore = (rawNutriScore != null &&
            ['A', 'B', 'C', 'D', 'E'].contains(rawNutriScore))
        ? rawNutriScore
        : null;

    // ── Calcul du risque glycémique (IG estimé simplifié)
    final gi = _estimateGlycemicIndex(
        sugars: sugars, carbs: carbs, nutriScore: nutriScore);
    final risk  = gi >= 70 ? 2 : (gi >= 55 ? 1 : 0);
    final label = risk == 2
        ? 'IG élevé 🔴'
        : (risk == 1 ? 'IG moyen 🟡' : 'IG faible ⚪');
    final advice = risk == 2
        ? 'Ce produit peut faire monter la glycémie rapidement. Consommez-le avec modération.'
        : (risk == 1
            ? 'Impact glycémique modéré. Attention aux quantités consommées.'
            : 'Faible impact sur la glycémie. Adapté aux diabétiques avec modération.');

    return FoodProduct(
      barcode:        barcode,
      name:           name,
      brand:          brand,
      imageUrl:       image,
      calories:       calories,
      sugars:         sugars,
      carbohydrates:  carbs,
      fat:            fat,
      proteins:       proteins,
      nutriScore:     nutriScore,
      glycemicRisk:   risk,
      glycemicLabel:  label,
      glycemicAdvice: advice,
    );
  }

  // ── Estimation de l'IG basée sur les valeurs nutritionnelles
  // Formule simplifiée : prend en compte le ratio sucres/glucides,
  // les calories et le nutriscore
  static int _estimateGlycemicIndex({
    required double sugars,
    required double carbs,
    String? nutriScore,
  }) {
    if (carbs == 0) return 15; // produit sans glucides = IG très bas

    // Ratio sucres / glucides totaux (plus élevé = IG plus haut)
    final sugarRatio = (sugars / carbs).clamp(0.0, 1.0);

    // Base estimée
    double gi = 40 + (sugarRatio * 55);

    // Ajustement Nutri-Score
    if (nutriScore == 'A') gi -= 10;
    if (nutriScore == 'B') gi -= 5;
    if (nutriScore == 'D') gi += 5;
    if (nutriScore == 'E') gi += 10;

    // Ajustement si très peu de glucides
    if (carbs < 5) gi = gi * 0.6;

    return gi.round().clamp(0, 100);
  }
}