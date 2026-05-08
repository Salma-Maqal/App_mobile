import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_colors.dart';
import 'nutrition_service.dart';

// ─────────────────────────────────────────
// Écran principal Nutrition
// ─────────────────────────────────────────
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  String _query = '';
  bool _searching = false;
  List<FoodProduct> _results = [];
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    if (_query.trim().isEmpty) return;
    setState(() { _searching = true; _searchError = null; _results = []; });

    final list = await NutritionService.searchByName(_query.trim());

    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = list;
      if (list.isEmpty) _searchError = 'Aucun résultat pour "$_query"';
    });
  }

  void _openProduct(FoodProduct product) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.c6,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nutrition 🍎',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.search_rounded, size: 20), text: 'Recherche'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 20), text: 'Scanner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Onglet 1 : Recherche par nom
          _SearchTab(
            controller: _searchController,
            query: _query,
            searching: _searching,
            results: _results,
            error: _searchError,
            onQueryChanged: (v) => setState(() => _query = v),
            onSearch: _doSearch,
            onProductTap: _openProduct,
          ),
          // ── Onglet 2 : Scanner barcode
          _ScanTab(onScanned: (barcode) async {
            _tabController.animateTo(0);
            setState(() { _searching = true; _results = []; _searchError = null; });
            final product = await NutritionService.searchByBarcode(barcode);
            if (!mounted) return;
            setState(() { _searching = false; });
            if (product != null) {
              _openProduct(product);
            } else {
              setState(() => _searchError = 'Produit introuvable (code: $barcode)');
            }
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Onglet Recherche
// ─────────────────────────────────────────
class _SearchTab extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final bool searching;
  final List<FoodProduct> results;
  final String? error;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearch;
  final ValueChanged<FoodProduct> onProductTap;

  const _SearchTab({
    required this.controller,
    required this.query,
    required this.searching,
    required this.results,
    required this.error,
    required this.onQueryChanged,
    required this.onSearch,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Barre de recherche
      Container(
        color: AppColors.c6,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              onSubmitted: (_) => onSearch(),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Ex: Nutella, lait, yaourt...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 22),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        })
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.c6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              elevation: 0,
            ),
            child: const Text('Chercher', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),

      // ── Résultats
      Expanded(
        child: searching
            ? const Center(child: CircularProgressIndicator(color: AppColors.c6))
            : error != null
                ? _EmptyState(message: error!)
                : results.isEmpty
                    ? _EmptyState(
                        icon: Icons.search_rounded,
                        message: 'Recherchez un produit alimentaire\npour voir ses informations nutritionnelles')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: results.length,
                        itemBuilder: (_, i) => _ProductCard(
                            product: results[i],
                            onTap: () => onProductTap(results[i])),
                      ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────
// Onglet Scanner
// ─────────────────────────────────────────
class _ScanTab extends StatefulWidget {
  final ValueChanged<String> onScanned;
  const _ScanTab({required this.onScanned});
  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  final MobileScannerController _scanController = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // ── Viewfinder caméra
      MobileScanner(
        controller: _scanController,
        onDetect: (capture) {
          if (_scanned) return;
          final barcode = capture.barcodes.firstOrNull?.rawValue;
          if (barcode != null && barcode.isNotEmpty) {
            setState(() => _scanned = true);
            widget.onScanned(barcode);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _scanned = false);
            });
          }
        },
      ),

      // ── Overlay avec viseur
      CustomPaint(
        painter: _ScanOverlayPainter(),
        child: const SizedBox.expand(),
      ),

      // ── Labels
      Positioned(
        top: 40,
        left: 0, right: 0,
        child: Text('Pointez vers un code-barres',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 8, color: Colors.black45)])),
      ),

      // ── Bouton torche
      Positioned(
        bottom: 50,
        left: 0, right: 0,
        child: Center(
          child: IconButton(
            onPressed: () => _scanController.toggleTorch(),
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 36),
          ),
        ),
      ),

      // ── Feedback scan réussi
      if (_scanned)
        Container(
          color: Colors.black45,
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 64),
              SizedBox(height: 12),
              Text('Code scanné !',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
    ]);
  }
}

// ─────────────────────────────────────────
// Carte produit dans la liste
// ─────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final FoodProduct product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  Color get _riskColor => product.glycemicRisk == 2
      ? const Color(0xFFE53935)
      : (product.glycemicRisk == 1 ? const Color(0xFFF57C00) : AppColors.c5);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.c3, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Image ou fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.imageUrl.isNotEmpty
                ? Image.network(product.imageUrl,
                    width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ImageFallback())
                : _ImageFallback(),
          ),
          const SizedBox(width: 14),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name.isNotEmpty ? product.name : 'Produit inconnu',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (product.brand.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(product.brand,
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(children: [
              // Calories
              _NutriChip(label: '${product.calories.round()} kcal', color: AppColors.c2, textColor: AppColors.textDark),
              const SizedBox(width: 6),
              // Sucres
              _NutriChip(label: '🍬 ${product.sugars.toStringAsFixed(1)}g', color: const Color(0xFFFFF9C4), textColor: const Color(0xFF7B6000)),
              const SizedBox(width: 6),
              // IG
              _NutriChip(
                  label: product.glycemicLabel,
                  color: _riskColor.withOpacity(0.12),
                  textColor: _riskColor),
            ]),
          ])),

          // Nutriscore
          if (product.nutriScore != null) ...[
            const SizedBox(width: 8),
            _NutriScore(grade: product.nutriScore!),
          ],

          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.c4),
        ]),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 64, height: 64,
    decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.fastfood_rounded, color: AppColors.c5, size: 30),
  );
}

class _NutriChip extends StatelessWidget {
  final String label;
  final Color color, textColor;
  const _NutriChip({required this.label, required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
  );
}

class _NutriScore extends StatelessWidget {
  final String grade;
  const _NutriScore({required this.grade});

  Color get _bg => switch (grade) {
    'A' => const Color(0xFF1E8F4E),
    'B' => const Color(0xFF88B931),
    'C' => const Color(0xFFF0C30F),
    'D' => const Color(0xFFE77D25),
    _   => const Color(0xFFE63E11),
  };

  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
    child: Center(child: Text(grade,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({this.icon = Icons.search_off_rounded, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.c2, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.c5, size: 40),
        ),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 15, height: 1.5)),
      ]),
    ),
  );
}

// ── Overlay dessin du viseur scanner
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dim  = size.width * 0.65;
    final left = (size.width - dim) / 2;
    final top  = (size.height - dim) / 2;
    final rect = Rect.fromLTWH(left, top, dim, dim);

    // Zone sombre autour du viseur
    final bgPaint = Paint()..color = Colors.black54;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16))),
      ),
      bgPaint,
    );

    // Coins du viseur
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 30.0;
    final corners = [
      [Offset(left, top), Offset(left + len, top), Offset(left, top + len)],
      [Offset(left + dim, top), Offset(left + dim - len, top), Offset(left + dim, top + len)],
      [Offset(left, top + dim), Offset(left + len, top + dim), Offset(left, top + dim - len)],
      [Offset(left + dim, top + dim), Offset(left + dim - len, top + dim), Offset(left + dim, top + dim - len)],
    ];
    for (final c in corners) {
      canvas.drawLine(c[1], c[0], paint);
      canvas.drawLine(c[0], c[2], paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────
// Écran détail produit
// ─────────────────────────────────────────
class ProductDetailScreen extends StatelessWidget {
  final FoodProduct product;
  const ProductDetailScreen({super.key, required this.product});

  Color get _riskColor => product.glycemicRisk == 2
      ? const Color(0xFFE53935)
      : (product.glycemicRisk == 1 ? const Color(0xFFF57C00) : AppColors.c5);

  Color get _riskBg => product.glycemicRisk == 2
      ? const Color(0xFFFFEBEE)
      : (product.glycemicRisk == 1 ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.c6,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          product.name.isNotEmpty ? product.name : 'Produit',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.c3, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(product.imageUrl,
                        width: 100, height: 100, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _HeroFallback())
                    : _HeroFallback(),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name.isNotEmpty ? product.name : 'Produit inconnu',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                if (product.brand.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(product.brand,
                      style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
                ],
                const SizedBox(height: 12),
                if (product.nutriScore != null)
                  Row(children: [
                    const Text('Nutri-Score : ',
                        style: TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                    _NutriScore(grade: product.nutriScore!),
                  ]),
              ])),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Alerte glycémique (diabète)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _riskBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _riskColor.withOpacity(0.3), width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: _riskColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.monitor_heart_rounded, color: _riskColor, size: 24),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Indice Glycémique estimé',
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(product.glycemicLabel,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _riskColor)),
                ]),
              ]),
              const SizedBox(height: 12),
              Text(product.glycemicAdvice,
                  style: TextStyle(fontSize: 14, color: _riskColor.withOpacity(0.8), height: 1.4)),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Tableau nutritionnel
          _SectionLabel(icon: Icons.pie_chart_rounded, label: 'Valeurs nutritionnelles / 100g'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.c3, width: 1.5),
            ),
            child: Column(children: [
              _NutrientRow(label: '🔥 Calories',    value: '${product.calories.round()} kcal',                isFirst: true),
              _NutrientRow(label: '🌾 Glucides',    value: '${product.carbohydrates.toStringAsFixed(1)} g'),
              _NutrientRow(label: '🍬 dont Sucres', value: '${product.sugars.toStringAsFixed(1)} g',          indent: true),
              _NutrientRow(label: '🥑 Graisses',   value: '${product.fat.toStringAsFixed(1)} g'),
              _NutrientRow(label: '💪 Protéines',  value: '${product.proteins.toStringAsFixed(1)} g',         isLast: true),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Conseils pour diabétiques
          _SectionLabel(icon: Icons.tips_and_updates_rounded, label: 'Conseils diabète'),
          const SizedBox(height: 12),
          _TipCard(
            icon: Icons.info_outline_rounded,
            color: AppColors.c6,
            text: 'Les informations nutritionnelles sont pour 100g. Adaptez selon votre portion réelle.',
          ),
          const SizedBox(height: 10),
          if (product.sugars > 15)
            _TipCard(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFE53935),
              text: 'Teneur en sucres élevée (${product.sugars.toStringAsFixed(1)}g/100g). Surveillez votre glycémie après consommation.',
            ),
          if (product.sugars <= 5)
            _TipCard(
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.c5,
              text: 'Teneur en sucres faible (${product.sugars.toStringAsFixed(1)}g/100g). Produit adapté aux diabétiques en portions normales.',
            ),
          const SizedBox(height: 10),
          _TipCard(
            icon: Icons.access_time_rounded,
            color: const Color(0xFF1565C0),
            text: 'Pensez à mesurer votre glycémie 1h30 à 2h après le repas pour suivre l\'impact réel.',
          ),

        ]),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 100, height: 100,
    decoration: BoxDecoration(color: AppColors.c2, borderRadius: BorderRadius.circular(14)),
    child: const Icon(Icons.fastfood_rounded, color: AppColors.c5, size: 48),
  );
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.c6),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
  ]);
}

class _NutrientRow extends StatelessWidget {
  final String label, value;
  final bool isFirst, isLast, indent;
  const _NutrientRow({
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
    this.indent = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(indent ? 32 : 16, 14, 16, 14),
    decoration: BoxDecoration(
      border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.c2, width: 1)),
      borderRadius: isFirst
          ? const BorderRadius.vertical(top: Radius.circular(14))
          : (isLast ? const BorderRadius.vertical(bottom: Radius.circular(14)) : BorderRadius.zero),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: 14,
              color: indent ? AppColors.textGrey : AppColors.textDark,
              fontWeight: indent ? FontWeight.w500 : FontWeight.w700)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
    ]),
  );
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _TipCard({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
          style: TextStyle(fontSize: 13, color: color, height: 1.4, fontWeight: FontWeight.w500))),
    ]),
  );
}