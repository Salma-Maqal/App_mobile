import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

// ──────────────────────────────────────────────
// MODÈLE PLAT
// ──────────────────────────────────────────────
class _Dish {
  final String emoji, name, desc, prep, level;
  final Color levelColor;
  final int cal, gluc, glucPct, prot, protPct, lip, lipPct;

  const _Dish({
    required this.emoji, required this.name, required this.desc,
    required this.prep, required this.level, required this.levelColor,
    required this.cal, required this.gluc, required this.glucPct,
    required this.prot, required this.protPct, required this.lip, required this.lipPct,
  });
}

const _dishes = [
  _Dish(emoji:'🫕', name:'Couscous Tfaya', desc:'Semoule fine avec oignons caramélisés et raisins secs',
    prep:'45 Min', level:'Moyen', levelColor:_kGreen,
    cal:650, gluc:94, glucPct:58, prot:45, protPct:28, lip:22, lipPct:14),
  _Dish(emoji:'🍲', name:'Harira', desc:'Soupe marocaine aux tomates, lentilles et pois chiches',
    prep:'60 Min', level:'Facile', levelColor:_kPurple,
    cal:310, gluc:40, glucPct:52, prot:18, protPct:23, lip:9, lipPct:25),
  _Dish(emoji:'🍗', name:'Tajine Poulet', desc:'Tajine au poulet avec olives et citron confit',
    prep:'75 Min', level:'Moyen', levelColor:_kGreen,
    cal:520, gluc:35, glucPct:27, prot:52, protPct:40, lip:20, lipPct:33),
  _Dish(emoji:'🥙', name:'Msemen', desc:'Crêpe feuilletée marocaine au beurre et miel',
    prep:'30 Min', level:'Facile', levelColor:_kPurple,
    cal:380, gluc:55, glucPct:58, prot:10, protPct:10, lip:15, lipPct:32),
  _Dish(emoji:'🫙', name:'Zaalouk', desc:'Caviar d\'aubergines aux tomates et épices',
    prep:'25 Min', level:'Facile', levelColor:_kPurple,
    cal:180, gluc:22, glucPct:49, prot:5, protPct:11, lip:8, lipPct:40),
  _Dish(emoji:'🍮', name:'Sellou', desc:'Pâte sucrée aux amandes, sésame et anis',
    prep:'20 Min', level:'Facile', levelColor:_kPurple,
    cal:520, gluc:60, glucPct:46, prot:14, protPct:11, lip:26, lipPct:43),
  _Dish(emoji:'🧆', name:'Briouates', desc:'Feuilletés croustillants au fromage ou viande hachée',
    prep:'35 Min', level:'Moyen', levelColor:_kGreen,
    cal:420, gluc:38, glucPct:36, prot:16, protPct:15, lip:22, lipPct:49),
  _Dish(emoji:'🥧', name:'Pastilla Poulet', desc:'Feuilleté sucré-salé au poulet, amandes et cannelle',
    prep:'90 Min', level:'Expert', levelColor:_kOrange,
    cal:580, gluc:52, glucPct:36, prot:34, protPct:23, lip:28, lipPct:41),
];

// Catégories pour les onglets
const _categories = ['Tout', 'Tajines', 'Soupes', 'Grillades', 'Couscous', 'Pâtiss.'];

// ──────────────────────────────────────────────
// SCREEN PRINCIPAL
// ──────────────────────────────────────────────
class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});
  @override State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  int _dishIndex = 0;
  int _portions = 1;
  int _catIndex = 0;
  bool _saving = false;

  // Search
  final _searchCtrl = TextEditingController();
  List<_Dish> _searchResults = [];
  bool _searchDone = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _prev() => setState(() { _dishIndex = (_dishIndex - 1 + _dishes.length) % _dishes.length; _portions = 1; });
  void _next() => setState(() { _dishIndex = (_dishIndex + 1) % _dishes.length; _portions = 1; });

  void _search(String q) {
    if (q.trim().isEmpty) { setState(() { _searchResults = []; _searchDone = false; }); return; }
    final r = _dishes.where((d) => d.name.toLowerCase().contains(q.toLowerCase())).toList();
    setState(() { _searchResults = r; _searchDone = true; });
  }

  Future<void> _addToJournal() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dish = _dishes[_dishIndex];
        await FirebaseFirestore.instance.collection('meals').add({
          'userId':    user.uid,
          'name':      dish.name,
          'emoji':     dish.emoji,
          'portions':  _portions,
          'calories':  dish.cal * _portions,
          'glucides':  dish.gluc * _portions,
          'proteines': dish.prot * _portions,
          'lipides':   dish.lip * _portions,
          'mealType':  'repas',
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (mounted) _showSuccessModal(dish);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSuccessModal(_Dish dish) {
    showDialog(
      context: context,
      barrierColor: const Color(0x883C2878),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(color: _kBgPurple, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(dish.emoji, style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 14),
              const Text('Repas ajouté !',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kDark)),
              const SizedBox(height: 8),
              Text('🍽️ ${dish.name} x$_portions',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPurple)),
              const SizedBox(height: 8),
              const Text('Votre repas a été ajouté à votre journal nutritionnel.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFFB0A8D8), fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _kPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Super !', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Sticky Header
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(color: _kBgPurple, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.chevron_left, color: _kPurple, size: 20),
                          ),
                        ),
                        const Spacer(),
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(text: 'Cuisine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kDark)),
                            WidgetSpan(child: SizedBox(width: 4)),
                            WidgetSpan(child: _Badge(text: 'MA')),
                          ]),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () { _tabController.animateTo(1); },
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(color: _kBgPurple, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.search, color: _kPurple, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: _kPurple,
                    unselectedLabelColor: const Color(0xFFB0A8D8),
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    indicatorColor: _kPurple,
                    indicatorWeight: 3,
                    dividerColor: const Color(0xFFF0EBFF),
                    tabs: const [
                      Tab(text: 'Plats MA'),
                      Tab(text: 'Recherche'),
                      Tab(text: 'Scanner'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CuisineTab(
                  dishIndex: _dishIndex,
                  portions: _portions,
                  catIndex: _catIndex,
                  onPrev: _prev,
                  onNext: _next,
                  onPortion: (d) => setState(() => _portions = (_portions + d).clamp(1, 5)),
                  onCat: (i) => setState(() => _catIndex = i),
                  onAdd: _saving ? null : _addToJournal,
                  saving: _saving,
                ),
                _SearchTab(
                  controller: _searchCtrl,
                  results: _searchResults,
                  searchDone: _searchDone,
                  onSearch: _search,
                  onSelect: (d) {
                    final idx = _dishes.indexOf(d);
                    if (idx >= 0) {
                      setState(() { _dishIndex = idx; _portions = 1; });
                      _tabController.animateTo(0);
                    }
                  },
                ),
                const _ScanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// TAB: PLATS MA (Carousel)
// ──────────────────────────────────────────────
class _CuisineTab extends StatelessWidget {
  final int dishIndex, portions, catIndex;
  final VoidCallback onPrev, onNext;
  final void Function(int) onPortion, onCat;
  final VoidCallback? onAdd;
  final bool saving;

  const _CuisineTab({
    required this.dishIndex, required this.portions, required this.catIndex,
    required this.onPrev, required this.onNext, required this.onPortion,
    required this.onCat, required this.onAdd, required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final dish = _dishes[dishIndex];
    final leftDish  = _dishes[(dishIndex - 1 + _dishes.length) % _dishes.length];
    final rightDish = _dishes[(dishIndex + 1) % _dishes.length];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Category scroll
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final active = catIndex == i;
                return GestureDetector(
                  onTap: () => onCat(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? _kPurple : Colors.white,
                      border: Border.all(color: active ? _kPurple : const Color(0xFFE8E0FF)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_categories[i],
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : _kGrey)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Carousel
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFF0EBFF), Colors.white],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
            padding: const EdgeInsets.only(top: 20, bottom: 0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DishThumb(emoji: leftDish.emoji),
                        const SizedBox(width: 10),
                        _DishMain(emoji: dish.emoji),
                        const SizedBox(width: 10),
                        _DishThumb(emoji: rightDish.emoji),
                      ],
                    ),
                    // Arrows
                    Positioned(
                      left: 12,
                      child: GestureDetector(
                        onTap: onPrev,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.15), blurRadius: 8)],
                          ),
                          alignment: Alignment.center,
                          child: const Text('‹', style: TextStyle(fontSize: 18, color: _kPurple, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      child: GestureDetector(
                        onTap: onNext,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.15), blurRadius: 8)],
                          ),
                          alignment: Alignment.center,
                          child: const Text('›', style: TextStyle(fontSize: 18, color: _kPurple, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  ],
                ),
                // Dots
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_dishes.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: i == dishIndex ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == dishIndex ? _kPurple : const Color(0xFFD6CFF7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // ── Dish detail
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Column(
              children: [
                Text(dish.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kDark)),
                const SizedBox(height: 4),
                Text(dish.desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB0A8D8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),

                // Portions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PortionBtn(label: '−', onTap: () => onPortion(-1)),
                    const SizedBox(width: 16),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text('🍽️', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 16),
                    Column(children: [
                      Text('$portions', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _kDark)),
                      const Text('portion(s)', style: TextStyle(fontSize: 12, color: Color(0xFFB0A8D8), fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(width: 16),
                    _PortionBtn(label: '+', onTap: () => onPortion(1)),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats 3
                Row(children: [
                  Expanded(child: _Stat3Card(icon:'⏱️', label:'Prépa', value: dish.prep, bg: const Color(0xFFF0EBFF), labelColor: _kGrey)),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat3Card(icon:'⭐', label:'Niveau', value: dish.level, bg: const Color(0xFFE8FAF5), labelColor: _kGreen, valueColor: dish.levelColor)),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat3Card(icon:'🔥', label:'Calories', value: '${dish.cal * portions} Cal', bg: const Color(0xFFFFF4EE), labelColor: _kOrange)),
                ]),
                const SizedBox(height: 16),

                // Macros
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F5FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Macronutriments',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kDark)),
                      const SizedBox(height: 12),
                      _MacroBar(label: 'Glucides', value: dish.gluc * portions, pct: dish.glucPct, color: _kPurple),
                      const SizedBox(height: 10),
                      _MacroBar(label: 'Protéines', value: dish.prot * portions, pct: dish.protPct, color: _kOrange),
                      const SizedBox(height: 10),
                      _MacroBar(label: 'Lipides', value: dish.lip * portions, pct: dish.lipPct, color: _kGreen),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAdd,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _kPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('+ Ajouter au journal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// TAB: RECHERCHE
// ──────────────────────────────────────────────
class _SearchTab extends StatelessWidget {
  final TextEditingController controller;
  final List<_Dish> results;
  final bool searchDone;
  final void Function(String) onSearch;
  final void Function(_Dish) onSelect;

  const _SearchTab({
    required this.controller, required this.results,
    required this.searchDone, required this.onSearch, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onSearch,
                  onSubmitted: onSearch,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kDark),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: _kGrey, size: 18),
                    hintText: 'Ex: Harira, Tajine, Nutella...',
                    hintStyle: const TextStyle(color: Color(0xFFC4BCE0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8E0FF), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8E0FF), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _kPurple, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => onSearch(controller.text),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  backgroundColor: _kPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Chercher', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results or hint
        Expanded(
          child: !searchDone
              ? const _SearchHint(
                  icon: '🔍',
                  text: 'Recherchez un plat marocain ou un produit alimentaire pour voir ses informations nutritionnelles',
                )
              : results.isEmpty
                  ? const _SearchHint(icon: '😕', text: 'Aucun résultat trouvé')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: results.length,
                      itemBuilder: (_, i) => _ResultCard(dish: results[i], onTap: () => onSelect(results[i])),
                    ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// TAB: SCANNER
// ──────────────────────────────────────────────
class _ScanTab extends StatelessWidget {
  const _ScanTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Scan viewfinder
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(
                  top: 16, left: 0, right: 0,
                  child: Text('Pointez vers un code-barres',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                // Viewfinder corners
                SizedBox(
                  width: 160, height: 160,
                  child: CustomPaint(painter: _ViewfinderPainter()),
                ),
                // Scan line animation
                const _ScanLine(),
                Positioned(
                  bottom: 14,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white24, shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('⚡', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Hint card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF0EBFF)),
            ),
            child: Column(
              children: const [
                Text('📦', style: TextStyle(fontSize: 32)),
                SizedBox(height: 8),
                Text(
                  'Scannez le code-barres d\'un produit alimentaire pour voir ses informations nutritionnelles automatiquement',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _kGrey, fontWeight: FontWeight.w600, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SOUS-WIDGETS
// ──────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: _kBgPurple, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kPurple2)),
  );
}

class _DishThumb extends StatelessWidget {
  final String emoji;
  const _DishThumb({required this.emoji});
  @override Widget build(BuildContext context) => Container(
    width: 70, height: 70,
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Opacity(opacity: 0.55, child: Text(emoji, style: const TextStyle(fontSize: 32))),
  );
}

class _DishMain extends StatelessWidget {
  final String emoji;
  const _DishMain({required this.emoji});
  @override Widget build(BuildContext context) => Container(
    width: 110, height: 110,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95), shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 8))],
    ),
    alignment: Alignment.center,
    child: Text(emoji, style: const TextStyle(fontSize: 52)),
  );
}

class _PortionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PortionBtn({required this.label, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: _kBgPurple, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kPurple)),
    ),
  );
}

class _Stat3Card extends StatelessWidget {
  final String icon, label, value;
  final Color bg, labelColor;
  final Color? valueColor;
  const _Stat3Card({required this.icon, required this.label, required this.value,
    required this.bg, required this.labelColor, this.valueColor});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: labelColor)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: valueColor ?? _kDark)),
    ]),
  );
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int value, pct;
  final Color color;
  const _MacroBar({required this.label, required this.value, required this.pct, required this.color});
  @override Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
    Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: pct / 100,
          minHeight: 7,
          backgroundColor: const Color(0xFFE8E0FF),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ),
    const SizedBox(width: 8),
    SizedBox(width: 60, child: Text('$pct% · ${value}g',
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGrey))),
  ]);
}

class _SearchHint extends StatelessWidget {
  final String icon, text;
  const _SearchHint({required this.icon, required this.text});
  @override Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFFB0A8D8), fontWeight: FontWeight.w600, height: 1.5)),
      ]),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  final _Dish dish;
  final VoidCallback onTap;
  const _ResultCard({required this.dish, required this.onTap});

  String _nsLabel() {
    if (dish.cal < 200) return 'A';
    if (dish.cal < 400) return 'B';
    if (dish.cal < 550) return 'C';
    return 'D';
  }
  Color _nsColor() {
    switch (_nsLabel()) {
      case 'A': return const Color(0xFF1E8F4E);
      case 'B': return const Color(0xFF88B931);
      case 'C': return const Color(0xFFF0C30F);
      default:  return const Color(0xFFE77D25);
    }
  }

  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0EBFF)),
        boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: _kBgPurple, borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: Text(dish.emoji, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dish.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDark)),
          const Text('Cuisine Marocaine', style: TextStyle(fontSize: 11, color: Color(0xFFB0A8D8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 5, runSpacing: 4, children: [
            _Chip(text: '🔥 ${dish.cal} kcal', bg: const Color(0xFFE8F8F2), color: _kGreen),
            _Chip(text: '🌾 ${dish.gluc}g gluc', bg: const Color(0xFFFFFBE8), color: const Color(0xFFB7860B)),
          ]),
        ])),
        const SizedBox(width: 8),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: _nsColor(), borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(_nsLabel(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ]),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg, color;
  const _Chip({required this.text, required this.bg, required this.color});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

// ──────────────────────────────────────────────
// SCAN PAINTERS
// ──────────────────────────────────────────────
class _ViewfinderPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    const r = 4.0; const s = 22.0;
    // TL
    canvas.drawLine(Offset(r, 0), Offset(s, 0), p);
    canvas.drawLine(Offset(0, r), Offset(0, s), p);
    // TR
    canvas.drawLine(Offset(size.width - s, 0), Offset(size.width - r, 0), p);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, s), p);
    // BL
    canvas.drawLine(Offset(r, size.height), Offset(s, size.height), p);
    canvas.drawLine(Offset(0, size.height - s), Offset(0, size.height - r), p);
    // BR
    canvas.drawLine(Offset(size.width - s, size.height), Offset(size.width - r, size.height), p);
    canvas.drawLine(Offset(size.width, size.height - s), Offset(size.width, size.height - r), p);
  }
  @override bool shouldRepaint(_) => false;
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override State<_ScanLine> createState() => _ScanLineState();
}
class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 0.8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Positioned(
      top: 160 * _anim.value,
      left: 40, right: 40,
      child: Container(height: 2,
        decoration: BoxDecoration(
          color: _kPurple.withOpacity(0.8),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.4), blurRadius: 6)],
        )),
    ),
  );
}
