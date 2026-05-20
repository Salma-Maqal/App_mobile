import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────
// Constantes couleurs design
// ─────────────────────────────────────────
const _kOrange1 = Color(0xFFFD9B71);
const _kOrange2 = Color(0xFFE17055);
const _kPurple  = Color(0xFF6C5CE7);
const _kPurple2 = Color(0xFFA29BFE);
const _kDark    = Color(0xFF2D2060);
const _kGrey    = Color(0xFF9E8DD0);
const _kBg      = Color(0xFFFFF8F5);

// ─────────────────────────────────────────
// Données activités
// ─────────────────────────────────────────
class _Activity {
  final String icon;
  final String name;
  final int calPerMin;
  final Color bgColor;

  const _Activity(this.icon, this.name, this.calPerMin, this.bgColor);
}

const _activities = [
  _Activity('🚶', 'Marche',      4,  Color(0xFFE8F8F2)),
  _Activity('🏃', 'Course',     10,  Color(0xFFFFF0F3)),
  _Activity('🏋️', 'Musculation', 8,  Color(0xFFF0EBFF)),
  _Activity('🚴', 'Vélo',        7,  Color(0xFFFFFBE8)),
  _Activity('🏊', 'Natation',    9,  Color(0xFFE8F4FF)),
  _Activity('🧘', 'Yoga',        3,  Color(0xFFE8FAF5)),
  _Activity('⚽', 'Football',    8,  Color(0xFFFFF4EE)),
  _Activity('💃', 'Danse',       5,  Color(0xFFF5EEFF)),
];

// ─────────────────────────────────────────
// SportScreen
// ─────────────────────────────────────────
class SportScreen extends StatefulWidget {
  const SportScreen({super.key});

  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen> {
  int _selectedIndex = -1; // index activité sélectionnée
  int _duration = 30;      // durée en minutes
  int _caloriesBurned = 0;
  bool _saving = false;

  int get _calPreview {
    if (_selectedIndex < 0) return 0;
    return _activities[_selectedIndex].calPerMin * _duration;
  }

  Future<void> _save() async {
    if (_selectedIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une activité d\'abord')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cal = _calPreview;
        await FirebaseFirestore.instance.collection('sport_entries').add({
          'userId':    user.uid,
          'activity':  _activities[_selectedIndex].name,
          'duration':  _duration,
          'calories':  cal,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() => _caloriesBurned += cal);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${_activities[_selectedIndex].name} enregistré ! −$cal Cal'),
            backgroundColor: _kOrange2,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header orange gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kOrange1, _kOrange2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Activité Physique 🏆',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 34),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Calories burned card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calories brûlées aujourd\'hui',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${_caloriesBurned + (_selectedIndex >= 0 ? _calPreview : 0)}',
                                  style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' Cal',
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Text(
                      'Choisir une activité',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: _kDark,
                      ),
                    ),
                  ),

                  // Activity grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _activities.length,
                      itemBuilder: (ctx, i) {
                        final act = _activities[i];
                        final selected = _selectedIndex == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: act.bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? _kOrange2 : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: selected
                                  ? [BoxShadow(color: _kOrange2.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                                  : [],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(act.icon, style: const TextStyle(fontSize: 28)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(act.name,
                                      style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w800, color: _kDark,
                                      ),
                                    ),
                                    Text('~${act.calPerMin} Cal/min',
                                      style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600, color: _kGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Duration selector
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF0EBFF)),
                      boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Durée de l\'activité',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kGrey),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _DurBtn(
                              label: '−',
                              onTap: () => setState(() => _duration = (_duration - 5).clamp(5, 300)),
                            ),
                            Expanded(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$_duration',
                                      style: const TextStyle(
                                        fontSize: 24, fontWeight: FontWeight.w900, color: _kDark,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' min',
                                      style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB0A8D8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _DurBtn(
                              label: '+',
                              onTap: () => setState(() => _duration = (_duration + 5).clamp(5, 300)),
                            ),
                          ],
                        ),
                        if (_selectedIndex >= 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '≈ $_calPreview Cal brûlées',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: _kOrange2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Save button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _kOrange2,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('+ Enregistrer l\'activité', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DurBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBFF),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900, color: _kPurple,
        )),
      ),
    );
  }
}