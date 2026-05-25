import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';

// ─────────────────────────────────────────
// Local palette aliases (uses AppColors)
// ─────────────────────────────────────────
const _kBg        = AppColors.bg;
const _kWhite     = AppColors.white;
const _kGreen1    = AppColors.resedaGreen;
const _kGreen2    = AppColors.fernGreen;
const _kGreen3    = AppColors.darkMoss;   // primary
const _kGreen4    = AppColors.pakistanGreen;
const _kGreenL    = AppColors.c2;         // CFE1B9
const _kGreenXL   = AppColors.c1;         // E7F5DC
const _kGrey      = AppColors.textGrey;

// ─────────────────────────────────────────
// Activity model
// ─────────────────────────────────────────
class _Act {
  final String icon, name;
  final int calPerMin;
  // 'stable' | 'lower' | 'raise'  — effet sur la glycémie
  final String glucoseImpact;
  const _Act(this.icon, this.name, this.calPerMin, this.glucoseImpact);
}

const _acts = [
  _Act('🚶', 'Marche',       4,  'stable'),
  _Act('🏃', 'Course',      10,  'lower'),
  _Act('🏋️', 'Musculation',  8,  'raise'),
  _Act('🚴', 'Vélo',         7,  'lower'),
  _Act('🏊', 'Natation',     9,  'stable'),
  _Act('🧘', 'Yoga',         3,  'stable'),
  _Act('⚽', 'Football',     8,  'lower'),
  _Act('💃', 'Danse',        5,  'stable'),
];

// ─────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────
class SportScreen extends StatefulWidget {
  const SportScreen({super.key});
  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _AppHeader(tab: _tab),
          Expanded(
            child: TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: const [_WalkingTab(), _LogTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Header + Custom TabBar
// ─────────────────────────────────────────
class _AppHeader extends StatelessWidget {
  final TabController tab;
  const _AppHeader({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGreen1, _kGreen3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // title row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _CircleBtn(
                    icon: Icons.chevron_left,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '🏃 Activité Physique',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kWhite,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  _GlucosePill(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // tab bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _kWhite.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: tab,
                  indicator: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(3),
                  labelColor: _kGreen3,
                  unselectedLabelColor: _kWhite,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '👣  Walking'),
                    Tab(text: '🏋️  Log Activity'),
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

// ═══════════════════════════════════════════════
// TAB 1 — WALKING TRACKER
// ═══════════════════════════════════════════════
class _WalkingTab extends StatefulWidget {
  const _WalkingTab();
  @override
  State<_WalkingTab> createState() => _WalkingTabState();
}

class _WalkingTabState extends State<_WalkingTab> {
  static const int _goal = 5000;

  bool   _running  = false;
  int    _steps    = 0;
  int    _seconds  = 0;
  double _dist     = 0;
  int    _calories = 0;
  Timer? _timer;

  // ── controls ──
  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _seconds++;
          _steps    += (_seconds % 3 == 0) ? 2 : 1;
          _dist     = double.parse((_steps * 0.00076).toStringAsFixed(2));
          _calories = (_steps * 0.04).round();
        });
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _steps = _seconds = _calories = 0;
      _dist = 0;
    });
  }

  // ── helpers ──
  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress  => (_steps / _goal).clamp(0.0, 1.0);
  int    get _pct       => (_progress * 100).round();
  bool   get _goalDone  => _steps >= _goal;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── build ──
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      child: Column(
        children: [
          // ── Diabetes warning banner ──
          const _DiabetesWarnBanner(),
          const SizedBox(height: 14),

          // circle
          _StepCircle(progress: _progress, steps: _steps, goal: _goal),
          const SizedBox(height: 18),

          // goal bar
          _GoalBar(pct: _pct, progress: _progress, goalDone: _goalDone),
          const SizedBox(height: 12),

          // ── Glucose zones ──
          const _GlucoseZonesCard(),
          const SizedBox(height: 16),

          // stats 2×2
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _MiniStat(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFE67E22),
                label: 'Calories',
                value: '$_calories',
                unit: 'kcal',
              ),
              _MiniStat(
                icon: Icons.map_outlined,
                iconColor: _kGreen2,
                label: 'Distance',
                value: _dist.toStringAsFixed(2),
                unit: 'km',
              ),
              _MiniStat(
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFF2E86AB),
                label: 'Temps',
                value: _timeStr,
                unit: '',
              ),
              _MiniStat(
                icon: Icons.favorite_outline_rounded,
                iconColor: const Color(0xFFC0392B),
                label: 'Rythme',
                value: _running ? '98' : '--',
                unit: 'bpm',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // start/stop + reset
          Row(
            children: [
              Expanded(child: _StartStopBtn(running: _running, onTap: _toggle)),
              if (_steps > 0) ...[
                const SizedBox(width: 10),
                _ResetBtn(onTap: _reset),
              ],
            ],
          ),

          // goal reached banner
          if (_goalDone) ...[
            const SizedBox(height: 16),
            _GoalDoneBanner(),
          ],
        ],
      ),
    );
  }
}

// ─── Step Circle ───
class _StepCircle extends StatelessWidget {
  final double progress;
  final int steps, goal;
  const _StepCircle({
    required this.progress,
    required this.steps,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 210,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 210, height: 210,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: 14,
                valueColor: AlwaysStoppedAnimation<Color>(
                    _kGreenL.withOpacity(0.5)),
              ),
            ),
            SizedBox(
              width: 210, height: 210,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 14,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(_kGreen2),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$steps',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: _kGreen4,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Steps',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kGrey,
                    )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGreenXL,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Goal: $goal',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kGreen2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Goal Bar ───
class _GoalBar extends StatelessWidget {
  final int pct;
  final double progress;
  final bool goalDone;
  const _GoalBar({
    required this.pct,
    required this.progress,
    required this.goalDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kGreenXL,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Goal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kGreen2,
                  )),
              Text(
                goalDone ? '🎯 Objectif atteint!' : '$pct% done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: goalDone ? _kGreen3 : _kGreen1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _kGreenL,
              valueColor: AlwaysStoppedAnimation<Color>(
                goalDone ? _kGreen3 : _kGreen2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Stat Card ───
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value, unit;
  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kGreen3.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kGrey,
                    )),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _kGreen4,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        TextSpan(
                          text: ' $unit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kGrey,
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
    );
  }
}

// ─── Start/Stop Button ───
class _StartStopBtn extends StatelessWidget {
  final bool running;
  final VoidCallback onTap;
  const _StartStopBtn({required this.running, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = running ? const Color(0xFFB03A2E) : _kGreen3;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              running ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: _kWhite,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              running ? 'Stop' : 'Start Walking',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _kWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reset Button ───
class _ResetBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: _kGreenXL,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGreenL, width: 1.5),
        ),
        child: Icon(Icons.refresh_rounded, color: _kGreen2, size: 22),
      ),
    );
  }
}

// ─── Goal Done Banner ───
class _GoalDoneBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreen1, _kGreen3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎉', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Text(
            'Objectif atteint ! Félicitations !',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _kWhite,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// TAB 2 — LOG ACTIVITY
// ═══════════════════════════════════════════════
class _LogTab extends StatefulWidget {
  const _LogTab();
  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  int  _sel      = -1;
  int  _duration = 30;
  bool _saving   = false;
  int  _todayCal = 0;

  int get _calPreview =>
      _sel < 0 ? 0 : _acts[_sel].calPerMin * _duration;

  Future<void> _save() async {
    if (_sel < 0) {
      _snack("Choisissez une activité d'abord", isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cal  = _calPreview;
        final name = _acts[_sel].name;
        await FirebaseFirestore.instance.collection('sport_entries').add({
          'userId':    user.uid,
          'activity':  name,
          'duration':  _duration,
          'calories':  cal,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          _todayCal += cal;
          _sel       = -1;
        });
        _snack('$name enregistré ! 🔥 −$cal Cal');
      }
    } catch (e) {
      _snack('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : _kGreen3,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Glucose reminder ──
          const _GlucoseReminderBanner(),
          const SizedBox(height: 14),

          // today's total banner
          if (_todayCal > 0) ...[
            _TodayCalBanner(calories: _todayCal),
            const SizedBox(height: 16),
          ],

          // section title
          const Text(
            'Choisir une activité',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kGreen4,
            ),
          ),
          const SizedBox(height: 12),

          // activities grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _acts.length,
            itemBuilder: (_, i) => _ActivityCard(
              act: _acts[i],
              selected: _sel == i,
              onTap: () => setState(() => _sel = i),
            ),
          ),
          const SizedBox(height: 16),

          // duration picker
          _DurationPicker(
            duration: _duration,
            calPreview: _calPreview,
            hasSelection: _sel >= 0,
            onMinus: () =>
                setState(() => _duration = (_duration - 5).clamp(5, 300)),
            onPlus: () =>
                setState(() => _duration = (_duration + 5).clamp(5, 300)),
          ),
          const SizedBox(height: 16),

          // save button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen3,
                foregroundColor: _kWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: _kWhite, strokeWidth: 2.5))
                  : const Text(
                      '+ Enregistrer l\'activité',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today Calories Banner ───
class _TodayCalBanner extends StatelessWidget {
  final int calories;
  const _TodayCalBanner({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreen1, _kGreen3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Calories brûlées aujourd'hui",
                style: TextStyle(
                  fontSize: 12,
                  color: _kGreenL,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$calories Cal',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _kWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Activity Card ───
class _ActivityCard extends StatelessWidget {
  final _Act act;
  final bool selected;
  final VoidCallback onTap;
  const _ActivityCard({
    required this.act,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _kGreen3 : _kGreenXL,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _kGreen2 : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kGreen3.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(act.icon, style: const TextStyle(fontSize: 26)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected ? _kWhite : _kGreen4,
                  ),
                ),
                Text(
                  '~${act.calPerMin} Cal/min',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? _kGreenL : _kGrey,
                  ),
                ),
                const SizedBox(height: 4),
                _GlucoseImpactBadge(
                  impact: act.glucoseImpact,
                  selected: selected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Duration Picker ───
class _DurationPicker extends StatelessWidget {
  final int duration, calPreview;
  final bool hasSelection;
  final VoidCallback onMinus, onPlus;
  const _DurationPicker({
    required this.duration,
    required this.calPreview,
    required this.hasSelection,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kGreen3.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Durée de l'activité",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoundBtn(label: '−', onTap: onMinus),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$duration',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: _kGreen4,
                        ),
                      ),
                      TextSpan(
                        text: ' min',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kGrey,
                        ),
                      ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _kGreenXL,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '≈ $calPreview Cal brûlées',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kGreen2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Diabetes-specific widgets (NEW)
// ─────────────────────────────────────────

// ─── Glucose Pill (header) ───
class _GlucosePill extends StatelessWidget {
  const _GlucosePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kWhite.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF7EE8A2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            '5.8 mmol',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kWhite,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Diabetes Warning Banner (Walking tab) ───
class _DiabetesWarnBanner extends StatelessWidget {
  const _DiabetesWarnBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF9A825), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Conseil diabète : Vérifiez votre glycémie avant de commencer. '
              'Zone idéale pour l\'effort : 7 – 13 mmol/L',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A5C00),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glucose Zones Card (Walking tab) ───
class _GlucoseZonesCard extends StatelessWidget {
  const _GlucoseZonesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kGreen3.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zones glycémie pendant effort',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kGreen4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ZoneChip(
                label: '< 5.5',
                sublabel: 'Hypoglycémie',
                bg: const Color(0xFFFDECEA),
                border: const Color(0xFFEFADB0),
                textColor: const Color(0xFF8B1C1C),
              ),
              const SizedBox(width: 6),
              _ZoneChip(
                label: '7 – 13',
                sublabel: 'Zone idéale',
                bg: _kGreenXL,
                border: _kGreenL,
                textColor: _kGreen3,
              ),
              const SizedBox(width: 6),
              _ZoneChip(
                label: '> 16',
                sublabel: 'Prudence',
                bg: const Color(0xFFFFF8E1),
                border: const Color(0xFFF9A825),
                textColor: const Color(0xFF7A5C00),
              ),
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
  const _ZoneChip({
    required this.label,
    required this.sublabel,
    required this.bg,
    required this.border,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glucose Impact Badge (Activity card) ───
class _GlucoseImpactBadge extends StatelessWidget {
  final String impact;
  final bool selected;
  const _GlucoseImpactBadge({
    required this.impact,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg, textColor;

    switch (impact) {
      case 'lower':
        label = '↓ Peut baisser';
        bg = selected
            ? _kWhite.withOpacity(0.2)
            : const Color(0xFFE6F1FB);
        textColor = selected ? _kWhite : const Color(0xFF185FA5);
        break;
      case 'raise':
        label = '↑ Peut hausser';
        bg = selected
            ? _kWhite.withOpacity(0.2)
            : const Color(0xFFFFF8E1);
        textColor = selected ? _kWhite : const Color(0xFF7A5C00);
        break;
      default: // 'stable'
        label = '— Glycémie stable';
        bg = selected ? _kWhite.withOpacity(0.2) : _kGreenXL;
        textColor = selected ? _kWhite : _kGreen3;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Glucose Reminder Banner (Log tab) ───
class _GlucoseReminderBanner extends StatelessWidget {
  const _GlucoseReminderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93B8F5), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: Color(0xFF185FA5),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Mesurez votre glycémie avant et après l\'activité. '
              'Certains sports peuvent faire chuter rapidement le sucre.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF185FA5),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────
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
        decoration: BoxDecoration(
          color: _kWhite.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _kWhite, size: 22),
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
        decoration: BoxDecoration(
          color: _kGreenXL,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kGreenL, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _kGreen2,
          ),
        ),
      ),
    );
  }
}