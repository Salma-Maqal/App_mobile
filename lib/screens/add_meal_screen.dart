import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_colors.dart';

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
      levelColor: AppColors.warning,
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
  _Dish(
    emoji:'🥗', name:'Salade César',
    desc:'Laitue romaine, poulet, parmesan, sauce César',
    prep:'15 Min', level:'Facile', levelColor:AppColors.primary,
    cal:350, gluc:15, glucPct:20, prot:25, protPct:35, lip:22, lipPct:45,
    category:'Salades', imageUrl:'assets/images/salade/salade_cesar.jpg', glycemicIndex:25,
  ),
  _Dish(
    emoji:'🥗', name:'Salade Marocaine',
    desc:'Tomates, oignons, concombre, coriandre',
    prep:'10 Min', level:'Facile', levelColor:AppColors.primary,
    cal:120, gluc:18, glucPct:60, prot:3, protPct:10, lip:4, lipPct:30,
    category:'Salades', imageUrl:'assets/images/salade/salade_marocaine.jpg', glycemicIndex:30,
  ),
  _Dish(
    emoji:'🐟', name:'Salade de Thon',
    desc:'Thon, maïs, tomates, œufs, olives',
    prep:'10 Min', level:'Facile', levelColor:AppColors.primary,
    cal:280, gluc:12, glucPct:17, prot:22, protPct:31, lip:16, lipPct:52,
    category:'Salades', imageUrl:'assets/images/salade/salade_thon.png', glycemicIndex:35,
  ),
  _Dish(
    emoji:'🥗', name:'Salade Grecque',
    desc:'Feta, olives, concombre, tomates, oignon',
    prep:'10 Min', level:'Facile', levelColor:AppColors.primary,
    cal:250, gluc:10, glucPct:16, prot:8, protPct:13, lip:18, lipPct:71,
    category:'Salades', imageUrl:'assets/images/salade/salade_grec.jpg', glycemicIndex:30,
  ),
  _Dish(
    emoji:'🥑', name:'Salade Avocat Crevettes',
    desc:'Avocat, crevettes, tomates cerises, citron',
    prep:'15 Min', level:'Facile', levelColor:AppColors.primary,
    cal:320, gluc:10, glucPct:12, prot:18, protPct:22, lip:24, lipPct:66,
    category:'Salades', imageUrl:'assets/images/salade/salade_crevette.jpg', glycemicIndex:25,
  ),
  _Dish(
    emoji:'🍲', name:'Harira',
    desc:'Soupe marocaine aux tomates, lentilles et pois chiches',
    prep:'60 Min', level:'Facile', levelColor:AppColors.primary,
    cal:310, gluc:40, glucPct:52, prot:18, protPct:23, lip:9, lipPct:25,
    category:'Soupes', imageUrl:'assets/images/soupe/harira.jpg', glycemicIndex:45,
  ),
  _Dish(
    emoji:'🍗', name:'Tajine Poulet',
    desc:'Poulet, olives, citron confit',
    prep:'75 Min', level:'Moyen', levelColor:AppColors.sport,
    cal:520, gluc:35, glucPct:27, prot:52, protPct:40, lip:20, lipPct:33,
    category:'Viande', imageUrl:'assets/images/viande/Tajine_Poulet.jpg', glycemicIndex:50,
  ),
  _Dish(
    emoji:'🥩', name:'Boulettes Kefta',
    desc:'Viande hachée, persil, oignon, épices',
    prep:'25 Min', level:'Facile', levelColor:AppColors.primary,
    cal:380, gluc:8, glucPct:8, prot:32, protPct:34, lip:25, lipPct:58,
    category:'Viande', imageUrl:'assets/images/viande/Kefta.jpg', glycemicIndex:20,
  ),
  _Dish(
    emoji:'🐟', name:'Saumon Grillé',
    desc:'Saumon frais, herbes, citron',
    prep:'20 Min', level:'Facile', levelColor:AppColors.primary,
    cal:420, gluc:2, glucPct:2, prot:40, protPct:38, lip:28, lipPct:60,
    category:'Poisson', imageUrl:'assets/images/poisson/Saumon.jpg', glycemicIndex:10,
  ),
  _Dish(
    emoji:'🥪', name:'Sandwich Poulet',
    desc:'Poulet grillé, crudités, sauce légère',
    prep:'10 Min', level:'Facile', levelColor:AppColors.primary,
    cal:450, gluc:45, glucPct:40, prot:30, protPct:27, lip:18, lipPct:33,
    category:'Snacks', imageUrl:'assets/images/snacks/Sandwich_Poulet.jpg', glycemicIndex:65,
  ),
  _Dish(
    emoji:'🍳', name:'Omelette Fromage',
    desc:'Œufs, fromage râpé, ciboulette',
    prep:'10 Min', level:'Facile', levelColor:AppColors.primary,
    cal:320, gluc:2, glucPct:3, prot:22, protPct:27, lip:25, lipPct:70,
    category:'Omelette', imageUrl:'assets/images/breakfast/Omelette_Fromage.jpg', glycemicIndex:5,
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

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  int _dishIndex = 0;
  int _portions = 1;
  int _catIndex = 0;
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
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ Aucun utilisateur connecté dans AddMealScreen');
    } else {
      print('✅ AddMealScreen - Utilisateur connecté: ${user.email}');
    }
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

  Future<void> _scanBarcodeOnlyApi() async {
    String? scannedBarcode;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _BarcodeScannerWidget(
              onBarcodeScanned: (barcode) {
                scannedBarcode = barcode;
                if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                }
              },
            ),
          ),
        );
      },
    );

    if (scannedBarcode == null || scannedBarcode!.isEmpty) {
      return;
    }

    setState(() => _isApiLoading = true);

    final url = Uri.parse(
      'https://fr.openfoodfacts.org/api/v0/product/$scannedBarcode.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1) {
          final scannedProduct = _Dish.fromOpenFoodFacts(data['product']);
          _selectProduct(scannedProduct);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${scannedProduct.name} trouvé !'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Code-barres non trouvé sur Open Food Facts'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur Scanner API: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApiLoading = false);
      }
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

  Future<void> _addToMeal() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Veuillez vous connecter pour ajouter des repas'),
            backgroundColor: AppColors.error,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
      return;
    }
    
    print('✅ Utilisateur connecté: ${user.email}');
    
    final dish = _currentActiveDish;
    
    try {
      // Structure des données pour Firestore
      final mealData = {
        'userId': user.uid,
        'userEmail': user.email,
        'name': dish.name,
        'mealName': dish.name,
        'emoji': dish.emoji,
        'calories': dish.cal * _portions,
        'glucides': dish.gluc * _portions,
        'proteines': dish.prot * _portions,
        'lipides': dish.lip * _portions,
        'portions': _portions,
        'glycemicIndex': dish.glycemicIndex,
        'timestamp1': Timestamp.now(),  // ← Utilisation de timestamp1
        'imageUrl': dish.imageUrl,
      };
      
      print('📝 Tentative d\'ajout: ${dish.name}');
      print('📊 Glucides: ${dish.gluc} × $_portions = ${dish.gluc * _portions}');
      
      final docRef = await FirebaseFirestore.instance
          .collection('meals')
          .add(mealData);
      
      print('✅ Succès! Document ID: ${docRef.id}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${dish.name} ajouté avec succès !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
         setState(() {
        _portions = 1;
        _searchCtrl.clear();
        _localSearchResults = [];
        _apiSearchResults = [];
        _scannedApiDish = null;});
        // Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Erreur Firebase: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 18),
                        ),
                      ),
                      const Text(
                        'Ajouter un repas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un plat ou produit API...',
                              hintStyle: const TextStyle(color: AppColors.textGrey),
                              prefixIcon: Icon(Icons.search, color: AppColors.textGrey, size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _scanBarcodeOnlyApi,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_searchCtrl.text.isEmpty && _scannedApiDish == null)
            Container(
              color: AppColors.white,
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
                                color: active ? AppColors.primary : AppColors.textGrey,
                              )),
                          if (active)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 16, height: 3,
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
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
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('PLATS CUISINÉS (LOCAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 1)),
          ),
          ..._localSearchResults.map((dish) => _buildSearchRow(dish)),
          const SizedBox(height: 20),
        ],
        if (_apiSearchResults.isNotEmpty || _isApiLoading) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Text('PRODUITS EN LIGNE (API)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1)),
                if (_isApiLoading) Padding(padding: const EdgeInsets.only(left: 10), child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
              ],
            ),
          ),
          ..._apiSearchResults.map((dish) => _buildSearchRow(dish)),
        ],
        if (_localSearchResults.isEmpty && _apiSearchResults.isEmpty && !_isApiLoading)
          Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Text("Aucun produit trouvé", style: TextStyle(color: AppColors.textGrey)))),
      ],
    );
  }

  Widget _buildSearchRow(_Dish dish) {
    return Card(
      color: AppColors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: dish.isFromApi && dish.imageUrl.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(dish.imageUrl, width: 40, height: 40, fit: BoxFit.cover))
            : Text(dish.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
        subtitle: Text('${dish.cal} kcal ${dish.isFromApi ? "/ 100g" : ""}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        trailing: Icon(dish.isFromApi ? Icons.cloud_download : Icons.arrow_forward_ios, color: AppColors.primary, size: 18),
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
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 90, left: 24, right: 24, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text(dish.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark))),
                  const SizedBox(height: 6),
                  Center(child: Text(dish.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500, height: 1.4))),
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
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _RoundBtn(icon: Icons.remove, onTap: () => setState(() => _portions = (_portions - 1).clamp(1, 10))),
                        Text('$_portions portion(s) ${dish.isFromApi ? "(x100g)" : ""}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        _RoundBtn(icon: Icons.add, onTap: () => setState(() => _portions = (_portions + 1).clamp(1, 10))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('MACRONUTRIMENTS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: 1.2)),
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
                  const Text('ANALYSE DIABÉTIQUE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _getRiskColor(dish.glycemicIndex).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _getRiskColor(dish.glycemicIndex).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${dish.glycemicIndex}', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1, color: _getRiskColor(dish.glycemicIndex))),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Indice Glycémique (IG)\nRisque ${_getRiskLevel(dish.glycemicIndex)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.2))),
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
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.chevron_left, color: AppColors.textDark)),
              ),
              const SizedBox(width: 20),
              Container(
                width: 170, height: 170,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 15))]),
                child: ClipOval(
                  child: dish.isFromApi && dish.imageUrl.isNotEmpty
                      ? Image.network(dish.imageUrl, fit: BoxFit.cover)
                      : Image.asset(dish.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.accentLight, child: Center(child: Text(dish.emoji, style: const TextStyle(fontSize: 60))))),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _next,
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.chevron_right, color: AppColors.textDark)),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            decoration: BoxDecoration(color: AppColors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, -5))]),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addToMeal,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
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

  Color _getRiskColor(int glycemicIndex) {
    if (glycemicIndex <= 55) return AppColors.success;
    if (glycemicIndex <= 70) return AppColors.warning;
    return AppColors.error;
  }

  String _getRiskLevel(int glycemicIndex) {
    if (glycemicIndex <= 55) return 'Faible';
    if (glycemicIndex <= 70) return 'Modéré';
    return 'Élevé';
  }
}

class _Badge extends StatelessWidget {
  final String icon, text;
  final Color? color;
  const _Badge({required this.icon, required this.text, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color?.withOpacity(0.1) ?? AppColors.accentLight, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [Text(icon), const SizedBox(width: 6), Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color ?? AppColors.primary))]),
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
      child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle), child: Icon(icon, color: AppColors.textDark, size: 20)),
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
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.bg)),
        child: Column(children: [Text(icon, style: const TextStyle(fontSize: 22)), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textDark)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))]),
      ),
    );
  }
}

class _BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  const _BarcodeScannerWidget({required this.onBarcodeScanned});

  @override
  State<_BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<_BarcodeScannerWidget> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner un produit'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _isProcessing = true;
                  widget.onBarcodeScanned(barcode.rawValue!);
                  return;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Text(
              'Placez le code-barres dans le cadre',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}