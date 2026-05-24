import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/diabetes_analyzer.dart';

// ──────────────────────────────────────────────
// COULEURS
// ──────────────────────────────────────────────
const _kPurple  = Color(0xFF6C5CE7);
const _kPurple2 = Color(0xFFA29BFE);
const _kOrange  = Color(0xFFE17055);
const _kGreen   = Color(0xFF00B894);
const _kDark    = Color(0xFF2D2060);
const _kGrey    = Color(0xFF9E8DD0);
const _kBgPurple= Color(0xFFF0EBFF);
const _kBgScaffold = Color(0xFFF7F8FC);

// ──────────────────────────────────────────────
// MODÈLE PLAT
// ──────────────────────────────────────────────
class _Dish {
  final String emoji, name, desc, prep, level, category, imageUrl;
  final Color levelColor;
  final int cal, gluc, glucPct, prot, protPct, lip, lipPct;
  final int glycemicIndex;
  final bool isFromApi; 

  const _Dish({
    required this.emoji, required this.name, required this.desc,
    required this.prep, required this.level, required this.levelColor,
    required this.cal, required this.gluc, required this.glucPct,
    required this.prot, required this.protPct, required this.lip, required this.lipPct,
    required this.category, required this.imageUrl, required this.glycemicIndex,
    this.isFromApi = false,
  });

  factory _Dish.fromOpenFoodFacts(Map<String, dynamic> json) {
    final nutrients = json['nutriments'] ?? {};
    final int calories = (nutrients['energy-kcal_100g'] ?? nutrients['energy-kcal'] ?? 0).toInt();
    final int carbohydrates = (nutrients['carbohydrates_100g'] ?? 0).toInt();
    final int proteins = (nutrients['proteins_100g'] ?? 0).toInt();
    final int fats = (nutrients['fat_100g'] ?? 0).toInt();
    final String brand = json['brands'] ?? 'Inconnue';

    int estimatedGI = 35;
    if (carbohydrates > 20) estimatedGI = 55;
    if (carbohydrates > 50) estimatedGI = 75;

    return _Dish(
      emoji: '📦',
      name: json['product_name_fr'] ?? json['product_name'] ?? 'Produit Inconnu',
      desc: 'Marque: $brand · Portion de 100g',
      prep: '--',
      level: 'Industriel',
      levelColor: _kOrange,
      cal: calories,
      gluc: carbohydrates, glucPct: 0,
      prot: proteins, protPct: 0,
      lip: fats, lipPct: 0,
      category: 'Open Food Facts',
      imageUrl: json['image_front_url'] ?? '',
      glycemicIndex: estimatedGI,
      isFromApi: true,
    );
  }
}

class _MealItem {
  final _Dish dish;
  final int portions;
  const _MealItem({required this.dish, required this.portions});

  int get totalCal   => dish.cal  * portions;
  int get totalGluc  => dish.gluc * portions;
  int get totalProt  => dish.prot * portions;
  int get totalLip   => dish.lip  * portions;
}

// ──────────────────────────────────────────────
// DONNÉES DES PLATS
// ──────────────────────────────────────────────
const _dishes = [
  // ==================== SALADES ====================
  _Dish(
    emoji:'🥗', name:'Salade César',
    desc:'Laitue romaine, poulet, parmesan, sauce César',
    prep:'15 Min', level:'Facile', levelColor:_kPurple,
    cal:350, gluc:15, glucPct:20, prot:25, protPct:35, lip:22, lipPct:45,
    category:'Salades', imageUrl:'assets/images/salade/salade_cesar.jpg', glycemicIndex:25,
  ),
  _Dish(
    emoji:'🥗', name:'Salade Marocaine',
    desc:'Tomates, oignons, concombre, coriandre',
    prep:'10 Min', level:'Facile', levelColor:_kPurple,
    cal:120, gluc:18, glucPct:60, prot:3, protPct:10, lip:4, lipPct:30,
    category:'Salades', imageUrl:'assets/images/salade/salade_marocaine.jpg', glycemicIndex:30,
  ),
  _Dish(
    emoji:'🐟', name:'Salade de Thon',
    desc:'Thon, maïs, tomates, œufs, olives',
    prep:'10 Min', level:'Facile', levelColor:_kPurple,
    cal:280, gluc:12, glucPct:17, prot:22, protPct:31, lip:16, lipPct:52,
    category:'Salades', imageUrl:'assets/images/salade/salade_thon.png', glycemicIndex:35,
  ),
  _Dish(
    emoji:'🥗', name:'Salade Grecque',
    desc:'Feta, olives, concombre, tomates, oignon',
    prep:'10 Min', level:'Facile', levelColor:_kPurple,
    cal:250, gluc:10, glucPct:16, prot:8, protPct:13, lip:18, lipPct:71,
    category:'Salades', imageUrl:'assets/images/salade/salade_grec.jpg', glycemicIndex:30,
  ),
  _Dish(
    emoji:'🥑', name:'Salade Avocat Crevettes',
    desc:'Avocat, crevettes, tomates cerises, citron',
    prep:'15 Min', level:'Facile', levelColor:_kPurple,
    cal:320, gluc:10, glucPct:12, prot:18, protPct:22, lip:24, lipPct:66,
    category:'Salades', imageUrl:'assets/images/salade/salade_crevette.jpg', glycemicIndex:25,
  ),

  // ==================== SOUPES ====================
  _Dish(
    emoji:'🍲', name:'Harira',
    desc:'Soupe marocaine aux tomates, lentilles et pois chiches',
    prep:'60 Min', level:'Facile', levelColor:_kPurple,
    cal:310, gluc:40, glucPct:52, prot:18, protPct:23, lip:9, lipPct:25,
    category:'Soupes', imageUrl:'assets/images/soupe/harira.jpg', glycemicIndex:45,
  ),
  _Dish(
    emoji:'🥔', name:'Velouté de Potiron',
    desc:'Potiron, crème, graines de courge',
    prep:'30 Min', level:'Facile', levelColor:_kPurple,
    cal:160, gluc:22, glucPct:55, prot:4, protPct:10, lip:6, lipPct:35,
    category:'Soupes', imageUrl:'assets/images/soupe/Potiron.jpg', glycemicIndex:65,
  ),
  _Dish(
    emoji:'🥕', name:'Soupe de Légumes',
    desc:'Carottes, poireaux, pommes de terre, céleri',
    prep:'25 Min', level:'Facile', levelColor:_kPurple,
    cal:120, gluc:18, glucPct:60, prot:4, protPct:13, lip:3, lipPct:27,
    category:'Soupes', imageUrl:'assets/images/soupe/legume.jpg', glycemicIndex:50,
  ),
  _Dish(
    emoji:'🍗', name:'Chorba Poulet',
    desc:'Soupe algérienne au poulet, vermicelles et pois chiches',
    prep:'45 Min', level:'Moyen', levelColor:_kGreen,
    cal:280, gluc:35, glucPct:50, prot:20, protPct:28, lip:8, lipPct:22,
    category:'Soupes', imageUrl:'assets/images/soupe/Poulet.jpg', glycemicIndex:55,
  ),
  _Dish(
    emoji:'🫘', name:'Soupe Lentilles',
    desc:'Lentilles corail, carottes, oignons, cumin',
    prep:'35 Min', level:'Facile', levelColor:_kPurple,
    cal:190, gluc:28, glucPct:59, prot:12, protPct:25, lip:3, lipPct:16,
    category:'Soupes', imageUrl:'assets/images/soupe/lentille.jpg', glycemicIndex:40,
  ),
  _Dish(
    emoji:'🥒', name:'Velouté Courgette',
    desc:'Courgettes, pommes de terre, menthe, crème',
    prep:'25 Min', level:'Facile', levelColor:_kPurple,
    cal:130, gluc:15, glucPct:46, prot:5, protPct:15, lip:6, lipPct:39,
    category:'Soupes', imageUrl:'assets/images/soupe/Courgette.jpg', glycemicIndex:50,
  ),

  // ==================== VIANDE ====================
  _Dish(
    emoji:'🍗', name:'Tajine Poulet',
    desc:'Poulet, olives, citron confit',
    prep:'75 Min', level:'Moyen', levelColor:_kGreen,
    cal:520, gluc:35, glucPct:27, prot:52, protPct:40, lip:20, lipPct:33,
    category:'Viande', imageUrl:'assets/images/viande/Tajine_Poulet.jpg', glycemicIndex:50,
  ),
  _Dish(
    emoji:'🥩', name:'Boulettes Kefta',
    desc:'Viande hachée, persil, oignon, épices',
    prep:'25 Min', level:'Facile', levelColor:_kPurple,
    cal:380, gluc:8, glucPct:8, prot:32, protPct:34, lip:25, lipPct:58,
    category:'Viande', imageUrl:'assets/images/viande/Kefta.jpg', glycemicIndex:20,
  ),
  _Dish(
    emoji:'🍢', name:'Brochettes de Bœuf',
    desc:'Bœuf tendre mariné, poivrons, oignons',
    prep:'30 Min', level:'Moyen', levelColor:_kGreen,
    cal:350, gluc:5, glucPct:6, prot:40, protPct:46, lip:18, lipPct:48,
    category:'Viande', imageUrl:'assets/images/viande/Boeuf.jpg', glycemicIndex:15,
  ),
  _Dish(
    emoji:'🍖', name:'Tajine Viande Pruneaux',
    desc:'Viande d\'agneau, pruneaux, amandes',
    prep:'90 Min', level:'Expert', levelColor:_kOrange,
    cal:650, gluc:45, glucPct:28, prot:40, protPct:25, lip:38, lipPct:47,
    category:'Viande', imageUrl:'assets/images/viande/Tajine_Viande.jpg', glycemicIndex:60,
  ),

  // ==================== POISSON ====================
  _Dish(
    emoji:'🐟', name:'Saumon Grillé',
    desc:'Saumon frais, herbes, citron',
    prep:'20 Min', level:'Facile', levelColor:_kPurple,
    cal:420, gluc:2, glucPct:2, prot:40, protPct:38, lip:28, lipPct:60,
    category:'Poisson', imageUrl:'assets/images/poisson/Saumon.jpg', glycemicIndex:10,
  ),
  _Dish(
    emoji:'🐠', name:'Tajine Poisson',
    desc:'Poisson, légumes, épices marocaines',
    prep:'45 Min', level:'Moyen', levelColor:_kGreen,
    cal:380, gluc:28, glucPct:30, prot:35, protPct:37, lip:14, lipPct:33,
    category:'Poisson', imageUrl:'assets/images/poisson/Tajine_poisson.jpg', glycemicIndex:45,
  ),
  _Dish(
    emoji:'🐟', name:'Sardines Farcies',
    desc:'Sardines fraîches farcies aux herbes',
    prep:'30 Min', level:'Moyen', levelColor:_kGreen,
    cal:320, gluc:5, glucPct:6, prot:28, protPct:35, lip:20, lipPct:59,
    category:'Poisson', imageUrl:'assets/images/poisson/Sardines.jpg', glycemicIndex:10,
  ),

  // ==================== SNACKS ====================
  _Dish(
    emoji:'🥪', name:'Sandwich Poulet',
    desc:'Poulet grillé, crudités, sauce légère',
    prep:'10 Min', level:'Facile', levelColor:_kPurple,
    cal:450, gluc:45, glucPct:40, prot:30, protPct:27, lip:18, lipPct:33,
    category:'Snacks', imageUrl:'assets/images/snacks/Sandwich_Poulet.jpg', glycemicIndex:65,
  ),
  _Dish(
    emoji:'🥙', name:'Panini Fromage',
    desc:'Pain panini, mozzarella, tomates, pesto',
    prep:'10 Min', level:'Facile', levelColor:_kPurple,
    cal:480, gluc:50, glucPct:42, prot:20, protPct:17, lip:22, lipPct:41,
    category:'Snacks', imageUrl:'assets/images/snacks/Panini_Fromage.jpg', glycemicIndex:70,
  ),
  _Dish(
    emoji:'🥙', name:'Msemen',
    desc:'Crêpe feuilletée marocaine au beurre et miel',
    prep:'30 Min', level:'Facile', levelColor:_kPurple,
    cal:380, gluc:55, glucPct:58, prot:10, protPct:10, lip:15, lipPct:32,
    category:'Snacks', imageUrl:'assets/images/snacks/Msemen.jpg', glycemicIndex:75,
  ),
  _Dish(
    emoji:'🧆', name:'Briouates',
    desc:'Feuilletés croustillants',
    prep:'35 Min', level:'Moyen', levelColor:_kGreen,
    cal:420, gluc:38, glucPct:36, prot:16, protPct:15, lip:22, lipPct:49,
    category:'Snacks', imageUrl:'assets/images/snacks/Briouates.jpg', glycemicIndex:70,
  ),

  // ==================== BOISSONS ====================
  _Dish(
    emoji:'🥤', name:'Jus d\'Orange',
    desc:'Jus d\'orange frais pressé',
    prep:'5 Min', level:'Facile', levelColor:_kPurple,
    cal:110, gluc:26, glucPct:96, prot:2, protPct:4, lip:0, lipPct:0,
    category:'Boissons', imageUrl:'assets/images/boissons/Orange.jpg', glycemicIndex:75,
  ),
  _Dish(
    emoji:'🍌', name:'Smoothie Banane',
    desc:'Banane, lait d\'amande, miel',
    prep:'5 Min', level:'Facile', levelColor:_kPurple,
    cal:200, gluc:40, glucPct:80, prot:5, protPct:10, lip:2, lipPct:10,
    category:'Boissons', imageUrl:'assets/images/boissons/Banane.jpg', glycemicIndex:65,
  ),
  _Dish(
    emoji:'🍃', name:'Thé à la Menthe',
    desc:'Thé vert, menthe fraîche, sucre',
    prep:'10 Min', level:'Facile', levelColor:_kPurple,
    cal:60, gluc:15, glucPct:100, prot:0, protPct:0, lip:0, lipPct:0,
    category:'Boissons', imageUrl:'assets/images/boissons/The.jpg', glycemicIndex:70,
  ),
  _Dish(
    emoji:'☕', name:'Café Noir',
    desc:'Café expresso',
    prep:'5 Min', level:'Facile', levelColor:_kPurple,
    cal:5, gluc:1, glucPct:100, prot:0, protPct:0, lip:0, lipPct:0,
    category:'Boissons', imageUrl:'assets/images/boissons/Cafe.jpg', glycemicIndex:0,
  ),

  // ==================== DESSERTS ====================
  _Dish(
    emoji:'🍮', name:'Sellou',
    desc:'Pâte sucrée aux amandes, sésame',
    prep:'20 Min', level:'Facile', levelColor:_kPurple,
    cal:520, gluc:60, glucPct:46, prot:14, protPct:11, lip:26, lipPct:43,
    category:'Desserts', imageUrl:'assets/images/snacks/Sellou.jpg', glycemicIndex:75,
  ),
  _Dish(
    emoji:'🍎', name:'Salade de Fruits',
    desc:'Fruits de saison, jus d\'orange, menthe',
    prep:'10 Min', level:'Facile', levelColor:_kPurple,
    cal:120, gluc:28, glucPct:93, prot:1, protPct:3, lip:1, lipPct:4,
    category:'Desserts', imageUrl:'assets/images/dessert/salade_fruits.jpg', glycemicIndex:55,
  ),
  _Dish(
    emoji:'🥞', name:'Crêpe Miel',
    desc:'Crêpe légère, miel d\'acacia',
    prep:'15 Min', level:'Facile', levelColor:_kPurple,
    cal:220, gluc:38, glucPct:69, prot:6, protPct:11, lip:5, lipPct:20,
    category:'Desserts', imageUrl:'assets/images/dessert/Crepe.jpg', glycemicIndex:80,
  ),

  // ==================== HEALTHY ====================
  _Dish(
    emoji:'🍗', name:'Poulet Vapeur Riz',
    desc:'Poulet vapeur, riz complet, légumes',
    prep:'25 Min', level:'Facile', levelColor:_kPurple,
    cal:480, gluc:55, glucPct:46, prot:38, protPct:32, lip:12, lipPct:22,
    category:'Healthy', imageUrl:'assets/images/healthy/poulet_vapeur_riz.jpg', glycemicIndex:55,
  ),

  // ==================== OMELETTE ====================
  _Dish(
    emoji:'🍳', name:'Omelette Fromage',
    desc:'Œufs, fromage râpé, ciboulette',
    prep:'10 Min', level:'Facile', levelColor:_kPurple,
    cal:320, gluc:2, glucPct:3, prot:22, protPct:27, lip:25, lipPct:70,
    category:'Omlette', imageUrl:'assets/images/breakfast/Omelette_Fromage.jpg', glycemicIndex:5,
  ),
];

const _categories = [
  'Tous', 'Salades', 'Soupes', 'Viande', 'Poisson',
  'Snacks', 'Boissons', 'Desserts', 'Healthy', 'Omelette',
];

// ──────────────────────────────────────────────
// SCREEN PRINCIPAL
// ──────────────────────────────────────────────
class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});
  @override State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  int _dishIndex = 0;
  int _portions  = 1;
  int _catIndex  = 0;
  bool _isApiLoading = false;

  _Dish? _scannedApiDish;

  final List<_MealItem> _selectedMeals = [];
  final _searchCtrl = TextEditingController();
  
  List<_Dish> _localSearchResults = [];
  List<_Dish> _apiSearchResults = [];

  _Dish get _currentActiveDish {
    if (_scannedApiDish != null) return _scannedApiDish!;
    final dishes = _filteredDishes;
    return dishes.isNotEmpty ? dishes[_dishIndex] : _dishes.first;
  }

  List<_Dish> get _filteredDishes {
    if (_catIndex == 0) return _dishes;
    final cat = _categories[_catIndex];
    return _dishes.where((d) => d.category == cat).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _localSearchResults = [];
        _apiSearchResults = [];
      });
      return;
    }

    final localMatches = _dishes
        .where((d) => d.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _localSearchResults = localMatches;
    });

    _searchApiOnline(query);
  }

  Future<void> _searchApiOnline(String query) async {
    setState(() => _isApiLoading = true);
    final url = Uri.parse(
      'https://fr.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=8'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200 && _searchCtrl.text.isNotEmpty) {
        final data = json.decode(response.body);
        final List products = data['products'] ?? [];
        setState(() {
          _apiSearchResults = products
              .where((p) => p['product_name'] != null)
              .map((p) => _Dish.fromOpenFoodFacts(p))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Erreur API Search: $e');
    } finally {
      setState(() => _isApiLoading = false);
    }
  }

  Future<void> _scanBarcodeOnlyApi(String barcode) async {
    setState(() => _isApiLoading = true);
    final url = Uri.parse('https://fr.openfoodfacts.org/api/v0/product/$barcode.json');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final scannedProduct = _Dish.fromOpenFoodFacts(data['product']);
          _selectProduct(scannedProduct);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scanner: ${scannedProduct.name} trouvé !'), backgroundColor: _kGreen),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code-barres non trouvé sur Open Food Facts'), backgroundColor: _kOrange),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur Scanner API: $e');
    } finally {
      setState(() => _isApiLoading = false);
    }
  }

  void _selectProduct(_Dish dish) {
    setState(() {
      _searchCtrl.clear();
      _localSearchResults = [];
      _apiSearchResults = [];
      _portions = 1;

      if (dish.isFromApi) {
        _scannedApiDish = dish; 
      } else {
        _scannedApiDish = null; 
        _catIndex = 0;
        _dishIndex = _dishes.indexWhere((d) => d.name == dish.name).clamp(0, _dishes.length - 1);
      }
    });
  }

  void _addToMeal() {
    final dish = _currentActiveDish;
    setState(() {
      final existingIdx = _selectedMeals.indexWhere((m) => m.dish.name == dish.name);
      if (existingIdx >= 0) {
        final existing = _selectedMeals[existingIdx];
        _selectedMeals[existingIdx] = _MealItem(dish: dish, portions: existing.portions + _portions);
      } else {
        _selectedMeals.add(_MealItem(dish: dish, portions: _portions));
      }
      _portions = 1;
      _scannedApiDish = null; 
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${dish.name} ajouté au repas'), backgroundColor: _kPurple, behavior: SnackBarBehavior.floating),
    );
  }

  void _prev() {
    if (_scannedApiDish != null) {
      setState(() => _scannedApiDish = null); 
      return;
    }
    if (_filteredDishes.isEmpty) return;
    setState(() {
      _dishIndex = (_dishIndex - 1 + _filteredDishes.length) % _filteredDishes.length;
      _portions = 1;
    });
  }

  void _next() {
    if (_scannedApiDish != null) {
      setState(() => _scannedApiDish = null); 
      return;
    }
    if (_filteredDishes.isEmpty) return;
    setState(() {
      _dishIndex = (_dishIndex + 1) % _filteredDishes.length;
      _portions = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgScaffold,
      body: Column(
        children: [
          // ── HEADER ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: _kBgScaffold, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back_ios_new, color: _kDark, size: 18),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Ajouter un repas',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kDark),
                        ),
                      ),
                      if (_selectedMeals.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(20)),
                          child: Text('${_selectedMeals.length} 🛒', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(color: _kBgScaffold, borderRadius: BorderRadius.circular(16)),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: 'Rechercher un plat ou produit API...',
                              hintStyle: TextStyle(color: Color(0xFFC4BCE0)),
                              prefixIcon: Icon(Icons.search, color: _kGrey, size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          _scanBarcodeOnlyApi('3017620422003'); 
                        },
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── HORIZONTAL CATEGORIES SLIDER (FIXED PARENTHESIS HERE) ──
          if (_searchCtrl.text.isEmpty && _scannedApiDish == null)
            Container(
              color: Colors.white,
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final active = _catIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() { _catIndex = i; _dishIndex = 0; _portions = 1; }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_categories[i],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                                color: active ? _kPurple : const Color(0xFFB0A8D8),
                              )),
                          if (active)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 16, height: 3,
                              decoration: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(2)),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── EXPANDED VIEW ──
          Expanded(
            child: _searchCtrl.text.isNotEmpty 
                ? _buildCombinedSearchView() 
                : _buildCuisineView(),       
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedSearchView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_localSearchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text('PLATS CUISINÉS (LOCAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kDark, letterSpacing: 1)),
          ),
          ..._localSearchResults.map((dish) => _buildSearchRow(dish)),
          const SizedBox(height: 20),
        ],

        if (_apiSearchResults.isNotEmpty || _isApiLoading) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                const Text('PRODUITS EN LIGNE (API)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kPurple, letterSpacing: 1)),
                if (_isApiLoading) const Padding(padding: EdgeInsets.only(left: 10), child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: _kPurple))),
              ],
            ),
          ),
          ..._apiSearchResults.map((dish) => _buildSearchRow(dish)),
        ],

        if (_localSearchResults.isEmpty && _apiSearchResults.isEmpty && !_isApiLoading)
          const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("Aucun produit trouvé", style: TextStyle(color: _kGrey)))),
      ],
    );
  }

  Widget _buildSearchRow(_Dish dish) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: dish.isFromApi && dish.imageUrl.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(dish.imageUrl, width: 40, height: 40, fit: BoxFit.cover))
            : Text(dish.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold, color: _kDark, fontSize: 14)),
        subtitle: Text('${dish.cal} kcal ${dish.isFromApi ? "/ 100g" : ""}', style: const TextStyle(color: _kGrey, fontSize: 12)),
        trailing: Icon(dish.isFromApi ? Icons.cloud_download : Icons.arrow_forward_ios, color: _kPurple, size: 18),
        onTap: () => _selectProduct(dish),
      ),
    );
  }

  Widget _buildCuisineView() {
    final dish = _currentActiveDish;

    return Stack(
      children: [
        Positioned(
          top: 100, left: 0, right: 0, bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 90, left: 24, right: 24, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text(dish.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _kDark))),
                  const SizedBox(height: 6),
                  Center(child: Text(dish.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _kGrey, fontWeight: FontWeight.w500, height: 1.4))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Badge(icon: '⏱', text: dish.prep),
                      const SizedBox(width: 12),
                      _Badge(icon: '⚡', text: dish.level, color: dish.levelColor),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _RoundBtn(icon: Icons.remove, onTap: () => setState(() => _portions = (_portions - 1).clamp(1, 10))),
                        Text('$_portions portion(s) ${dish.isFromApi ? "(x100g)" : ""}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kDark)),
                        _RoundBtn(icon: Icons.add, onTap: () => setState(() => _portions = (_portions + 1).clamp(1, 10))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('MACRONUTRIMENTS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _kDark, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MacroCard(icon: '🔥', value: '${dish.cal * _portions}', label: 'Calories'),
                      _MacroCard(icon: '🌾', value: '${dish.gluc * _portions}g', label: 'Glucides'),
                      _MacroCard(icon: '🍗', value: '${dish.prot * _portions}g', label: 'Protéines'),
                      _MacroCard(icon: '🥑', value: '${dish.lip * _portions}g', label: 'Lipides'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('ANALYSE DIABÉTIQUE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _kDark, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DiabetesAnalyzer.riskColor(dish.glycemicIndex).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: DiabetesAnalyzer.riskColor(dish.glycemicIndex).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${dish.glycemicIndex}', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1, color: DiabetesAnalyzer.riskColor(dish.glycemicIndex))),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Indice Glycémique (IG)\nRisque ${DiabetesAnalyzer.riskLevel(dish.glycemicIndex).toLowerCase()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kDark, height: 1.2))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _prev,
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.chevron_left, color: _kDark)),
              ),
              const SizedBox(width: 20),
              Container(
                width: 170, height: 170,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 15))]),
                child: ClipOval(
                  child: dish.isFromApi && dish.imageUrl.isNotEmpty
                      ? Image.network(dish.imageUrl, fit: BoxFit.cover)
                      : Image.asset(dish.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _kBgPurple, child: Center(child: Text(dish.emoji, style: const TextStyle(fontSize: 60))))),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _next,
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.chevron_right, color: _kDark)),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, -5))]),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addToMeal,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: _kPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                    child: const Text('Ajouter au repas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// COMPOSANTS AUXILIAIRES
// ──────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String icon, text;
  final Color? color;
  const _Badge({required this.icon, required this.text, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color?.withOpacity(0.1) ?? const Color(0xFFF0EBFF), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [Text(icon), const SizedBox(width: 6), Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color ?? _kPurple))]),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, color: _kDark, size: 20)),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String icon, value, label;
  const _MacroCard({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0F1F5))),
        child: Column(children: [Text(icon, style: const TextStyle(fontSize: 22)), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _kDark)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kGrey))]),
      ),
    );
  }
}