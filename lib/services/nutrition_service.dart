import 'dart:convert';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════
// MODEL — FoodProduct
// ═══════════════════════════════════════════════════════════
class FoodProduct {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final double calories;       // kcal / 100g
  final double sugars;         // g / 100g
  final double carbohydrates;  // g / 100g
  final double fat;            // g / 100g
  final double proteins;       // g / 100g
  final String? nutriScore;    // A B C D E
  final int glycemicRisk;      // 0=faible 1=moyen 2=élevé
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

  // ─── Helper باش تعرف واش المنتج معروف ─────────────────────
  bool get isValid => name.isNotEmpty;

  // ─── calories لكمية معينة (مثلاً 150g) ────────────────────
  double caloriesForQuantity(double grams) => (calories * grams) / 100;

  // ─── glucides لكمية معينة ──────────────────────────────────
  double carbsForQuantity(double grams) => (carbohydrates * grams) / 100;
}

// ═══════════════════════════════════════════════════════════
// SERVICE — NutritionService
// ═══════════════════════════════════════════════════════════
class NutritionService {
  static const String _baseUrl = 'https://world.openfoodfacts.org';
  static const Duration _timeout = Duration(seconds: 10);

  // ─── Cache باش ما نعاودوش نفس الطلب ───────────────────────
  static final Map<String, FoodProduct> _barcodeCache = {};
  static final Map<String, List<FoodProduct>> _nameCache = {};

  // ───────────────────────────────────────────────────────────
  // بارcode  ←  بحث بـ
  // ───────────────────────────────────────────────────────────
  static Future<FoodProduct?> searchByBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return null;

    // رجّع من cache إلا كان موجود
    if (_barcodeCache.containsKey(trimmed)) return _barcodeCache[trimmed];

    try {
      final uri = Uri.parse('$_baseUrl/api/v0/product/$trimmed.json');
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) return null;

      final product = _parseProduct(
        data['product'] as Map<String, dynamic>,
        trimmed,
      );

      if (product.isValid) _barcodeCache[trimmed] = product;
      return product.isValid ? product : null;
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────
  // اسم  ←  بحث بـ
  // ───────────────────────────────────────────────────────────
  static Future<List<FoodProduct>> searchByName(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // رجّع من cache إلا كان موجود
    if (_nameCache.containsKey(trimmed)) return _nameCache[trimmed]!;

    try {
      final encoded = Uri.encodeComponent(trimmed);
      final uri = Uri.parse(
        '$_baseUrl/cgi/search.pl'
        '?search_terms=$encoded'
        '&search_simple=1'
        '&action=process'
        '&json=1'
        '&page_size=10',
      );
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = (data['products'] as List<dynamic>?) ?? [];

      final products = rawList
          .map((p) => _parseProduct(
                p as Map<String, dynamic>,
                p['code']?.toString() ?? '',
              ))
          .where((p) => p.isValid)
          .toList();

      _nameCache[trimmed] = products;
      return products;
    } catch (_) {
      return [];
    }
  }

  // ───────────────────────────────────────────────────────────
  // Parser
  // ───────────────────────────────────────────────────────────
  static FoodProduct _parseProduct(Map<String, dynamic> p, String barcode) {
    final nutriments = (p['nutriments'] as Map<String, dynamic>?) ?? {};

    double getValue(String key) {
      final v = nutriments[key];
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final name  = p['product_name']?.toString()?.trim() ??
                  p['product_name_fr']?.toString()?.trim() ??
                  '';
    final brand = p['brands']?.toString()?.trim() ?? '';
    final image = p['image_front_url']?.toString() ??
                  p['image_url']?.toString() ??
                  '';

    final calories = getValue('energy-kcal_100g');
    final sugars   = getValue('sugars_100g');
    final carbs    = getValue('carbohydrates_100g');
    final fat      = getValue('fat_100g');
    final proteins = getValue('proteins_100g');

    final rawScore = (p['nutriscore_grade'] ?? p['nutrition_grade_fr'])
        ?.toString()
        .toUpperCase();
    final nutriScore = (['A', 'B', 'C', 'D', 'E'].contains(rawScore))
        ? rawScore
        : null;

    // ─── Glycemic Index ────────────────────────────────────
    final gi    = _estimateGlycemicIndex(sugars: sugars, carbs: carbs, nutriScore: nutriScore);
    final risk  = gi >= 70 ? 2 : (gi >= 55 ? 1 : 0);
    final label = switch (risk) {
      2 => 'IG élevé 🔴',
      1 => 'IG moyen 🟡',
      _ => 'IG faible ⚪',
    };
    final advice = switch (risk) {
      2 => 'Ce produit peut faire monter la glycémie rapidement. Consommez-le avec modération.',
      1 => 'Impact glycémique modéré. Attention aux quantités consommées.',
      _ => 'Faible impact sur la glycémie. Adapté aux diabétiques avec modération.',
    };

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

  // ───────────────────────────────────────────────────────────
  // Glycemic Index estimation
  // ───────────────────────────────────────────────────────────
  static int _estimateGlycemicIndex({
    required double sugars,
    required double carbs,
    String? nutriScore,
  }) {
    if (carbs == 0) return 15;

    final sugarRatio = (sugars / carbs).clamp(0.0, 1.0);
    double gi = 40 + (sugarRatio * 55);

    gi += switch (nutriScore) {
      'A' => -10.0,
      'B' => -5.0,
      'D' => 5.0,
      'E' => 10.0,
      _   => 0.0,
    };

    if (carbs < 5) gi *= 0.6;

    return gi.round().clamp(0, 100);
  }

  // ─── Clear cache (مثلاً عند logout) ───────────────────────
  static void clearCache() {
    _barcodeCache.clear();
    _nameCache.clear();
  }
}
