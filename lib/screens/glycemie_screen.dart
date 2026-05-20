import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────
// Constantes couleurs
// ─────────────────────────────────────────
const _kPurple  = Color(0xFF6C5CE7);
const _kPurple2 = Color(0xFFA29BFE);
const _kOrange  = Color(0xFFE17055);
const _kOrange1 = Color(0xFFFD9B71);
const _kDark    = Color(0xFF2D2060);
const _kGrey    = Color(0xFF9E8DD0);
const _kGreen   = Color(0xFF00B894);
const _kYellow  = Color(0xFFFDCB6E);
const _kRed     = Color(0xFFD63031);
const _kBlue    = Color(0xFF74B9FF);

// ─────────────────────────────────────────
// Moments de mesure
// ─────────────────────────────────────────
const _moments = ['À jeun', 'Avant repas', 'Après repas', 'Coucher'];

// ─────────────────────────────────────────
// Zones de référence
// ─────────────────────────────────────────
class _RefZone {
  final Color color;
  final String name;
  final String range;
  const _RefZone(this.color, this.name, this.range);
}

const _refZones = [
  _RefZone(_kBlue,   'Hypoglycémie',     '< 70 mg/dL'),
  _RefZone(_kGreen,  'Normal (à jeun)',   '70 – 100 mg/dL'),
  _RefZone(_kYellow, 'Pré-diabète',       '100 – 125 mg/dL'),
  _RefZone(_kOrange, 'Diabète (élevé)',   '126 – 200 mg/dL'),
  _RefZone(_kRed,    'Très élevé',        '> 200 mg/dL'),
];

// ─────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────
String _zoneLabel(double v) {
  if (v < 70)  return '⚠️ Hypoglycémie';
  if (v <= 100) return '✅ Normal (à jeun)';
  if (v <= 125) return '⚠️ Pré-diabète';
  if (v <= 200) return '🔴 Diabète (élevé)';
  return '🆘 Très élevé';
}

// ─────────────────────────────────────────
// GlycemieScreen
// ─────────────────────────────────────────
class GlycemieScreen extends StatefulWidget {
  const GlycemieScreen({super.key});

  @override
  State<GlycemieScreen> createState() => _GlycemieScreenState();
}

class _GlycemieScreenState extends State<GlycemieScreen> {
  int _selectedMoment = 0;
  final _controller = TextEditingController();
  bool _saving = false;

  // Last measure data (loaded from Firestore)
  double? _lastValue;
  String? _lastMoment;
  String? _lastTime;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLast() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('glycemie_entries')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        final d = snap.docs.first.data();
        final ts = (d['timestamp'] as Timestamp?)?.toDate();
        setState(() {
          _lastValue  = (d['value'] as num?)?.toDouble();
          _lastMoment = d['moment'] as String?;
          _lastTime   = ts != null
              ? '${ts.day}/${ts.month}/${ts.year} · ${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}'
              : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final raw = double.tryParse(_controller.text.trim());
    if (raw == null || raw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez une valeur valide (ex: 95)')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('glycemie_entries').add({
          'userId':    user.uid,
          'value':     raw,
          'moment':    _moments[_selectedMoment],
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Mesure enregistrée : $raw mg/dL — ${_zoneLabel(raw)}'),
            backgroundColor: _kPurple,
          ));
          setState(() {
            _lastValue  = raw;
            _lastMoment = _moments[_selectedMoment];
            _lastTime   = 'Maintenant';
          });
          _controller.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8FF),
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
                  border: Border(bottom: BorderSide(color: Color(0xFFF0EBFF))),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EBFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.chevron_left, color: _kPurple, size: 20),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Glycémie 🩸',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900, color: _kDark,
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
                  // Last measure card
                  _LastMeasureCard(
                    value: _lastValue,
                    moment: _lastMoment,
                    time: _lastTime,
                  ),

                  const SizedBox(height: 12),

                  // Add measure card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF0EBFF)),
                      boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ajouter une mesure',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDark),
                        ),
                        const SizedBox(height: 12),

                        // Moment tabs
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_moments.length, (i) {
                            final active = _selectedMoment == i;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedMoment = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFFFFF0E8) : Colors.white,
                                  border: Border.all(
                                    color: active ? _kOrange : const Color(0xFFE8E0FF),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _moments[i],
                                  style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700,
                                    color: active ? _kOrange : _kGrey,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),

                        // Input row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800, color: _kDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ex: 95',
                                  hintStyle: TextStyle(color: _kGrey.withOpacity(0.5)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _kOrange, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _kOrange, width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _kOrange, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('mg/dL',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: _kOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('+ Enregistrer la mesure',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Reference zones card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF0EBFF)),
                      boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Zones de référence',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDark),
                        ),
                        const SizedBox(height: 12),
                        ..._refZones.map((z) => Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10, height: 10,
                                    decoration: BoxDecoration(color: z.color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(z.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kDark),
                                  )),
                                  Text(z.range,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kGrey),
                                  ),
                                ],
                              ),
                            ),
                            if (z != _refZones.last)
                              const Divider(height: 1, color: Color(0xFFF0EBFF)),
                          ],
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
// Dernière mesure card
// ─────────────────────────────────────────
class _LastMeasureCard extends StatelessWidget {
  final double? value;
  final String? moment;
  final String? time;

  const _LastMeasureCard({this.value, this.moment, this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dernière mesure',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 8),
          if (value != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value!.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text('mg/dL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _zoneLabel(value!),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 6),
              Text(
                '${moment ?? ''} · $time',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ] else
            Text(
              'Aucune mesure enregistrée',
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}