import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────
// Constantes couleurs
// ─────────────────────────────────────────
const _kBlue1  = Color(0xFF74B9FF);
const _kBlue2  = Color(0xFF0984E3);
const _kDark   = Color(0xFF2D2060);
const _kGoal   = 2000; // ml objectif

// ─────────────────────────────────────────
// Options rapides
// ─────────────────────────────────────────
class _QuickOpt {
  final String icon;
  final int ml;
  final String label;
  const _QuickOpt(this.icon, this.ml, this.label);
}

const _quickOpts = [
  _QuickOpt('☕', 150,  'Café'),
  _QuickOpt('🥤', 250,  'Verre'),
  _QuickOpt('🧃', 500,  'Bouteille'),
  _QuickOpt('🫙', 1000, 'Grande'),
];

// ─────────────────────────────────────────
// HydratationScreen
// ─────────────────────────────────────────
class HydratationScreen extends StatefulWidget {
  const HydratationScreen({super.key});

  @override
  State<HydratationScreen> createState() => _HydratationScreenState();
}

class _HydratationScreenState extends State<HydratationScreen> {
  int _selectedOpt = 0;
  int _totalToday = 0;
  final _customController = TextEditingController();
  bool _saving = false;

  // History entries today
  final List<Map<String, dynamic>> _todayEntries = [];

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snap = await FirebaseFirestore.instance
          .collection('water_entries')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('timestamp', descending: true)
          .get();
      if (mounted) {
        int total = 0;
        final entries = <Map<String, dynamic>>[];
        for (final doc in snap.docs) {
          final d = doc.data();
          total += (d['ml'] as num?)?.toInt() ?? 0;
          entries.add(d);
        }
        setState(() {
          _totalToday = total;
          _todayEntries
            ..clear()
            ..addAll(entries);
        });
      }
    } catch (_) {}
  }

  Future<void> _add(int ml) async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('water_entries').add({
          'userId':    user.uid,
          'ml':        ml,
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() {
            _totalToday += ml;
            _todayEntries.insert(0, {'ml': ml, 'icon': _quickOpts[_selectedOpt].icon});
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('+$ml mL ajoutés 💧'),
            backgroundColor: _kBlue2,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addCustom() {
    final ml = int.tryParse(_customController.text.trim());
    if (ml == null || ml <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez une quantité valide (ex: 300)')),
      );
      return;
    }
    _customController.clear();
    _add(ml);
  }

  double get _progress => (_totalToday / _kGoal).clamp(0.0, 1.0);
  int get _pct => (_progress * 100).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: Column(
        children: [
          // ── Header
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE8F4FF))),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.chevron_left, color: _kBlue2, size: 20),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Hydratation 💧',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900, color: _kBlue2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 34),
                  ],
                ),
              ),
            ),
          ),

          // ── Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Water progress card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kBlue1, _kBlue2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // Text side
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Objectif quotidien',
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: '$_totalToday',
                                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                  TextSpan(
                                    text: ' mL',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.8)),
                                  ),
                                ]),
                              ),
                              Text(
                                '/ $_kGoal mL',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$_pct% de l\'objectif',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.85)),
                              ),
                            ],
                          ),
                        ),
                        // Bottle SVG-like widget
                        _WaterBottle(progress: _progress),
                      ],
                    ),
                  ),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0 mL', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kBlue1)),
                            Text('$_kGoal mL', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kBlue1)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE8F4FF),
                            valueColor: const AlwaysStoppedAnimation<Color>(_kBlue2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick amount buttons (3 in a row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _quickOpts.take(3).toList().asMap().entries.map((e) {
                        final i = e.key;
                        final opt = e.value;
                        final selected = _selectedOpt == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedOpt = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFFE8F4FF) : Colors.white,
                                border: Border.all(
                                  color: selected ? _kBlue2 : const Color(0xFFE8F4FF),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: _kBlue2.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                children: [
                                  Text(opt.icon, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(height: 4),
                                  Text('${opt.ml} mL', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kBlue2)),
                                  Text(opt.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kBlue1)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Large bottle option (1000ml)
                  GestureDetector(
                    onTap: () => setState(() => _selectedOpt = 3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _selectedOpt == 3 ? const Color(0xFFE8F4FF) : Colors.white,
                        border: Border.all(
                          color: _selectedOpt == 3 ? _kBlue2 : const Color(0xFFE8F4FF),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: _kBlue2.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('🫙', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 10),
                          Text('1000 mL', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kBlue2)),
                          SizedBox(width: 8),
                          Text('Grande', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kBlue1)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Custom input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kDark),
                            decoration: InputDecoration(
                              hintText: 'Quantité (mL)',
                              hintStyle: TextStyle(color: _kBlue1.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE8F4FF), width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE8F4FF), width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _kBlue2, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _addCustom,
                          child: Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: _kBlue2,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Text('+', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Add button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : () => _add(_quickOpts[_selectedOpt].ml),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _kBlue2,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                '+ Ajouter ${_quickOpts[_selectedOpt].ml} mL',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Today's history card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8F4FF)),
                      boxShadow: [BoxShadow(color: _kBlue2.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Historique du jour',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDark),
                        ),
                        const SizedBox(height: 10),
                        if (_todayEntries.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Aucune entrée pour l\'instant',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB0C8E8)),
                              ),
                            ),
                          )
                        else
                          ..._todayEntries.take(5).map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Text(e['icon'] ?? '💧', style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                const Expanded(child: Text('Eau ajoutée', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kDark))),
                                Text('+${e['ml']} mL', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kBlue2)),
                              ],
                            ),
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Water bottle widget
// ─────────────────────────────────────────
class _WaterBottle extends StatelessWidget {
  final double progress;
  const _WaterBottle({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54, height: 90,
      child: CustomPaint(
        painter: _BottlePainter(progress),
      ),
    );
  }
}

class _BottlePainter extends CustomPainter {
  final double progress;
  _BottlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paintOutline = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final paintFill = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final paintWater = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final paintNeck = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    // Neck
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.33, 0, size.width * 0.33, 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(neckRect, paintNeck);

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 12, size.width - 12, size.height - 12),
      const Radius.circular(12),
    );
    canvas.drawRRect(bodyRect, paintFill);
    canvas.drawRRect(bodyRect, paintOutline);

    // Water fill
    final fillHeight = (size.height - 12) * progress;
    final fillTop = 12 + (size.height - 12) * (1 - progress);
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, fillTop, size.width - 12, fillHeight),
      const Radius.circular(12),
    );
    canvas.save();
    canvas.clipRRect(bodyRect);
    canvas.drawRRect(fillRect, paintWater);
    canvas.restore();

    // Highlight
    final hlPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(12, 20, 8, 30), const Radius.circular(4)),
      hlPaint,
    );
  }

  @override
  bool shouldRepaint(_BottlePainter old) => old.progress != progress;
}