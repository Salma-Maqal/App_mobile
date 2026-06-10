import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health/health.dart';
import '../app_colors.dart';

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});
  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _currentSteps = 0;
  int _currentCalories = 0;
  double _currentDistance = 0.0;
  bool _isAuthorized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _initGoogleFit();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _initGoogleFit() async {
    setState(() => _isLoading = true);
    
    try {
      // Demander permissions (API correcte pour health 13.x)
      final types = [
        HealthDataType.STEPS,
        HealthDataTypes.STEPS, // Alternative
      ];
      
      final permissions = [
        HealthDataType.STEPS,
      ];
      
      final authorized = await Health().requestAuthorization(permissions);
      
      if (!authorized && mounted) {
        setState(() {
          _isAuthorized = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Permission Google Fit refusée'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      setState(() => _isAuthorized = true);
      
      // Charger les données d'aujourd'hui
      await _loadTodayData();
      
    } catch (e) {
      print('Erreur Google Fit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTodayData() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    try {
      // Jbed les steps (méthode correcte pour health 13.x)
      final health = Health();
      final stepsData = await health.getHealthDataFromTypes(
        startOfDay, 
        endOfDay, 
        [HealthDataType.STEPS]
      );
      
      int totalSteps = 0;
      for (final point in stepsData) {
        if (point.value is int) {
          totalSteps += point.value as int;
        }
      }
      
      setState(() {
        _currentSteps = totalSteps;
        _currentCalories = (totalSteps * 0.04).round();
        _currentDistance = totalSteps * 0.00076;
      });
      
      // Sauvegarder dans Firestore
      await _saveToFirestore();
      
    } catch (e) {
      print('Erreur chargement données: $e');
    }
  }

  Future<void> _saveToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    try {
      // Vérifier si déjà enregistré aujourd'hui
      final existing = await FirebaseFirestore.instance
          .collection('sport_entries')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .where('activity', isEqualTo: 'Google Fit Walking')
          .get();
      
      if (existing.docs.isEmpty && _currentSteps > 0) {
        await FirebaseFirestore.instance.collection('sport_entries').add({
          'userId': user.uid,
          'activity': 'Google Fit Walking',
          'steps': _currentSteps,
          'duration': (_currentSteps ~/ 100).clamp(1, 999),
          'distance': _currentDistance,
          'calories': _currentCalories,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('✅ Données Google Fit sauvegardées: ${_currentSteps} steps');
      }
    } catch (e) {
      print('Erreur sauvegarde: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _AppHeader(tab: _tab),
          Expanded(
            child: TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _WalkingTab(
                  steps: _currentSteps,
                  calories: _currentCalories,
                  distance: _currentDistance,
                  isLoading: _isLoading,
                  isAuthorized: _isAuthorized,
                  onRefresh: _loadTodayData,
                ),
                const _LogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Walking Tab (avec Google Fit)
// ─────────────────────────────────────────
class _WalkingTab extends StatelessWidget {
  final int steps;
  final int calories;
  final double distance;
  final bool isLoading;
  final bool isAuthorized;
  final VoidCallback onRefresh;

  const _WalkingTab({
    required this.steps,
    required this.calories,
    required this.distance,
    required this.isLoading,
    required this.isAuthorized,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final goal = 5000;
    final progress = (steps / goal).clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        child: Column(
          children: [
            const _DiabetesWarnBanner(),
            const SizedBox(height: 14),
            
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Connexion à Google Fit...'),
                    ],
                  ),
                ),
              )
            else if (!isAuthorized)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Autorisation Google Fit requise',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Veuillez autoriser l\'accès aux données de santé',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: onRefresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Steps Circle
              Center(
                child: SizedBox(
                  width: 210, height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 210, height: 210,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.c1.withOpacity(0.5),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.fernGreen),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            steps > 999 ? '${(steps/1000).toStringAsFixed(1)}k' : '$steps',
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: AppColors.pakistanGreen,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Steps', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.c1, borderRadius: BorderRadius.circular(20)),
                            child: Text('Goal: $goal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.fernGreen)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 18),
              
              // Progress bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.c1, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daily Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fernGreen)),
                        Text('$pct% done', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkMoss)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.c2,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.fernGreen),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              const _GlucoseZonesCard(),
              const SizedBox(height: 16),
              
              // Stats grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFE67E22),
                    label: 'Calories',
                    value: '$calories',
                    unit: 'kcal',
                  ),
                  _StatCard(
                    icon: Icons.map_outlined,
                    iconColor: AppColors.fernGreen,
                    label: 'Distance',
                    value: distance.toStringAsFixed(2),
                    unit: 'km',
                  ),
                  _StatCard(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFF2E86AB),
                    label: 'Durée estimée',
                    value: '${steps ~/ 100}',
                    unit: 'min',
                  ),
                  _StatCard(
                    icon: Icons.favorite_outline_rounded,
                    iconColor: const Color(0xFFC0392B),
                    label: 'Rythme',
                    value: steps > 0 ? '${(steps / ((steps ~/ 100).clamp(1, 999) * 60)).toStringAsFixed(1)}' : '--',
                    unit: 'steps/s',
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Données synchronisées automatiquement avec Google Fit',
                        style: TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Log Tab (activités manuelles)
// ─────────────────────────────────────────
class _LogTab extends StatefulWidget {
  const _LogTab();
  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  int _sel = -1;
  int _duration = 30;
  bool _saving = false;

  final List<Map<String, dynamic>> _activities = [
    {'icon': '🚶', 'name': 'Marche', 'calPerMin': 4, 'impact': 'stable'},
    {'icon': '🏃', 'name': 'Course', 'calPerMin': 10, 'impact': 'lower'},
    {'icon': '🏋️', 'name': 'Musculation', 'calPerMin': 8, 'impact': 'raise'},
    {'icon': '🚴', 'name': 'Vélo', 'calPerMin': 7, 'impact': 'lower'},
    {'icon': '🏊', 'name': 'Natation', 'calPerMin': 9, 'impact': 'stable'},
    {'icon': '🧘', 'name': 'Yoga', 'calPerMin': 3, 'impact': 'stable'},
    {'icon': '⚽', 'name': 'Football', 'calPerMin': 8, 'impact': 'lower'},
    {'icon': '💃', 'name': 'Danse', 'calPerMin': 5, 'impact': 'stable'},
  ];

  int get _calPreview => _sel < 0 ? 0 : _activities[_sel]['calPerMin'] * _duration;

  Future<void> _save() async {
    if (_sel < 0) {
      _showSnackBar('Choisissez une activité d\'abord', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('sport_entries').add({
          'userId': user.uid,
          'activity': _activities[_sel]['name'],
          'duration': _duration,
          'calories': _calPreview,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          _sel = -1;
          _duration = 30;
        });
        _showSnackBar('✅ ${_activities[_sel]['name']} enregistré !');
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GlucoseReminderBanner(),
          const SizedBox(height: 14),
          const Text(
            'Choisir une activité',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.pakistanGreen),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _activities.length,
            itemBuilder: (_, i) => _ActivityCard(
              activity: _activities[i],
              selected: _sel == i,
              onTap: () => setState(() => _sel = i),
            ),
          ),
          const SizedBox(height: 16),
          _DurationPicker(
            duration: _duration,
            calPreview: _calPreview,
            hasSelection: _sel >= 0,
            onMinus: () => setState(() => _duration = (_duration - 5).clamp(5, 300)),
            onPlus: () => setState(() => _duration = (_duration + 5).clamp(5, 300)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkMoss,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5))
                  : const Text('+ Enregistrer l\'activité', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Composants UI (inchangés)
// ─────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  final TabController tab;
  const _AppHeader({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.resedaGreen, AppColors.darkMoss],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _CircleBtn(icon: Icons.chevron_left, onTap: () => Navigator.pop(context)),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '🏃 Activité Physique',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: 0.2),
                      ),
                    ),
                  ),
                  const _GlucosePill(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                height: 40,
                decoration: BoxDecoration(color: AppColors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: tab,
                  indicator: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(3),
                  labelColor: AppColors.darkMoss,
                  unselectedLabelColor: AppColors.white,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '👣 Walking (Fit)'),
                    Tab(text: '🏋️ Log Activity'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value, unit;
  const _StatCard({required this.icon, required this.iconColor, required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.darkMoss.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.pakistanGreen)),
                      if (unit.isNotEmpty) TextSpan(text: ' $unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                    ],
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

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final bool selected;
  final VoidCallback onTap;
  const _ActivityCard({required this.activity, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkMoss : AppColors.c1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.fernGreen : Colors.transparent, width: 2),
          boxShadow: selected ? [BoxShadow(color: AppColors.darkMoss.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(activity['icon'], style: const TextStyle(fontSize: 26)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: selected ? AppColors.white : AppColors.pakistanGreen)),
                Text('~${activity['calPerMin']} Cal/min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? AppColors.c2 : AppColors.textGrey)),
                const SizedBox(height: 4),
                _ImpactBadge(impact: activity['impact'], selected: selected),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactBadge extends StatelessWidget {
  final String impact;
  final bool selected;
  const _ImpactBadge({required this.impact, required this.selected});

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg, textColor;

    switch (impact) {
      case 'lower':
        label = '↓ Peut baisser';
        bg = selected ? AppColors.white.withOpacity(0.2) : const Color(0xFFE6F1FB);
        textColor = selected ? AppColors.white : const Color(0xFF185FA5);
        break;
      case 'raise':
        label = '↑ Peut hausser';
        bg = selected ? AppColors.white.withOpacity(0.2) : const Color(0xFFFFF8E1);
        textColor = selected ? AppColors.white : const Color(0xFF7A5C00);
        break;
      default:
        label = '— Glycémie stable';
        bg = selected ? AppColors.white.withOpacity(0.2) : AppColors.c1;
        textColor = selected ? AppColors.white : AppColors.darkMoss;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final int duration, calPreview;
  final bool hasSelection;
  final VoidCallback onMinus, onPlus;
  const _DurationPicker({required this.duration, required this.calPreview, required this.hasSelection, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.darkMoss.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Durée de l'activité", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoundBtn(label: '−', onTap: onMinus),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(text: '$duration', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.pakistanGreen)),
                      TextSpan(text: ' min', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                    ],
                  ),
                ),
              ),
              _RoundBtn(label: '+', onTap: onPlus),
            ],
          ),
          if (hasSelection) ...[
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.c1, borderRadius: BorderRadius.circular(20)),
                child: Text('≈ $calPreview Cal brûlées', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fernGreen)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RoundBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.c1, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.c2, width: 1.5)),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.fernGreen)),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
  }
}

class _GlucosePill extends StatelessWidget {
  const _GlucosePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF7EE8A2), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          const Text('5.8 mmol', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white)),
        ],
      ),
    );
  }
}

class _DiabetesWarnBanner extends StatelessWidget {
  const _DiabetesWarnBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF9A825), width: 0.8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Conseil diabète : Vérifiez votre glycémie avant de commencer. Zone idéale pour l\'effort : 7 – 13 mmol/L',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7A5C00), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlucoseZonesCard extends StatelessWidget {
  const _GlucoseZonesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.darkMoss.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Zones glycémie pendant effort', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.pakistanGreen)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ZoneChip(label: '< 5.5', sublabel: 'Hypoglycémie', bg: const Color(0xFFFDECEA), border: const Color(0xFFEFADB0), textColor: const Color(0xFF8B1C1C)),
              const SizedBox(width: 6),
              _ZoneChip(label: '7 – 13', sublabel: 'Zone idéale', bg: AppColors.c1, border: AppColors.c2, textColor: AppColors.darkMoss),
              const SizedBox(width: 6),
              _ZoneChip(label: '> 16', sublabel: 'Prudence', bg: const Color(0xFFFFF8E1), border: const Color(0xFFF9A825), textColor: const Color(0xFF7A5C00)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  final String label, sublabel;
  final Color bg, border, textColor;
  const _ZoneChip({required this.label, required this.sublabel, required this.bg, required this.border, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border, width: 0.8)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textColor), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _GlucoseReminderBanner extends StatelessWidget {
  const _GlucoseReminderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF93B8F5), width: 0.8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 17, color: Color(0xFF185FA5)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Mesurez votre glycémie avant et après l\'activité. Certains sports peuvent faire chuter rapidement le sucre.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF185FA5), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}