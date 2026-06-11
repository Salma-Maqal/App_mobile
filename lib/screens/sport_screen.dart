import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

// ─── Color Palette ────────────────────────────────────────────────
const Color kNavy       = Color(0xFF1A3A5C);
const Color kBackground = Color(0xFFF2F5FA);
const Color kCardBg     = Color(0xFFFFFFFF);
const Color kBorder     = Color(0xFFDDE3EF);
const Color kTextMuted  = Color(0xFF7A8EAA);
const Color kOrange     = Color(0xFFFFA726);
const Color kOrangeBg   = Color(0xFFFFF3E0);
const Color kRedBg      = Color(0xFFFCEAEA);
const Color kRed        = Color(0xFFE53935);
const Color kGreen      = Color(0xFF4CAF50);
const Color kInfoBg     = Color(0xFFEBF3FF);
const Color kRingBg     = Color(0xFFE8F0FA);
const Color kBarColor   = Color(0xFFB8D4F0);
const Color kBarToday   = Color(0xFF378ADD);

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});
  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen> {
  StreamSubscription<StepCount>? _subscription;
  Timer? _timer;

  int _steps     = 0; // Valeur brute du capteur système
  int _baseSteps = 0; // Valeur de référence au début de la session
  int _seconds   = 0;
  bool _isRunning = false;

  // Weekly steps loaded from Firestore (index 0=Mon … 6=Sun)
  List<double> _weeklySteps = [0, 0, 0, 0, 0, 0, 0];
  bool _weeklyLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklySteps();
    _initPedometerBackgroundListening(); // Optionnel: commence à écouter le capteur en arrière-plan pour avoir une valeur brute à jour
  }

  // Permet d'avoir la valeur brute du capteur dès l'ouverture de l'écran
  void _initPedometerBackgroundListening() {
    Pedometer.stepCountStream.listen((StepCount e) {
      if (!mounted) return;
      // Si l'application ne tourne pas, on met juste à jour la valeur brute sans changer l'affichage de la session
      if (!_isRunning && _seconds == 0) {
        setState(() {
          _steps = e.steps;
          _baseSteps = e.steps; 
        });
      } else if (!_isRunning) {
        setState(() {
          _steps = e.steps;
        });
      }
    }).onError((error) {
      debugPrint("Erreur Pedometer initialisation: $error");
    });
  }

  // ── Derived ───────────────────────────────────────────────────────
  int    get _currentSteps => (_steps - _baseSteps).clamp(0, 99999);
  int    get _currentMin   => (_seconds / 60).floor();
  int    get _currentSec   => _seconds % 60;
  double get _km           => _currentSteps * 0.0008;
  int    get _kcal         => (_currentSteps * 0.04).round();
  double get _kmh          => _seconds > 0 ? (_km / (_seconds / 3600)) : 0.0;
  int    get _todayIndex   => (DateTime.now().weekday - 1).clamp(0, 6);

  // ── Load weekly steps from Firestore ─────────────────────────────
  Future<void> _loadWeeklySteps() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _weeklyLoading = false); return; }

    final now  = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start  = DateTime(monday.year, monday.month, monday.day);
    final end    = start.add(const Duration(days: 7));

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).collection('activities')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThan: end)
          .get();

      final totals = List<double>.filled(7, 0);
      for (final doc in snap.docs) {
        final ts = (doc['timestamp'] as Timestamp).toDate();
        final idx = (ts.weekday - 1).clamp(0, 6);
        totals[idx] += (doc['steps'] as num).toDouble();
      }

      if (mounted) setState(() { _weeklySteps = totals; _weeklyLoading = false; });
    } catch (e) {
      debugPrint("Erreur chargement graphique: $e");
      if (mounted) setState(() => _weeklyLoading = false);
    }
  }

  // ── Controls ──────────────────────────────────────────────────────
  Future<void> _start() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) return;
    
    setState(() { 
      _isRunning = true; 
      _seconds = 0; // Remise à zéro du temps pour la nouvelle session
      _baseSteps = _steps; // La base de calcul devient la valeur actuelle du capteur
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning) setState(() => _seconds++);
    });

    _subscription = Pedometer.stepCountStream.listen((StepCount e) {
      if (_isRunning) {
        setState(() {
          _steps = e.steps;
        });
      }
    });
  }

  void _pause()  => setState(() => _isRunning = false);
  void _resume() => setState(() => _isRunning = true);

  Future<void> _finish() async {
    // 1. On coupe immédiatement les flux pour figer l'interface
    _subscription?.cancel();
    _timer?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    
    // On capture les données de la session en cours
    final int stepsToSave = _currentSteps;
    final int durationToSave = _currentMin;
    final double kmToSave = double.parse(_km.toStringAsFixed(2));
    final int kcalToSave = _kcal;

    if (user != null && stepsToSave > 0) {
      try {
        await FirebaseFirestore.instance
            .collection('users').doc(user.uid).collection('activities').add({
          'steps':        stepsToSave,
          'duration_min': durationToSave,
          'distance_km':  kmToSave,
          'calories':     kcalToSave,
          'timestamp':    Timestamp.fromDate(DateTime.now()),
        });

        // Mise à jour immédiate de la barre du jour dans l'UI
        setState(() {
          _weeklySteps[_todayIndex] =
              (_weeklySteps[_todayIndex] + stepsToSave).clamp(0, 99999);
        });
      } catch (e) {
        debugPrint("Erreur lors de la sauvegarde Firestore: $e");
      }
    }

    // 2. RÉINITIALISATION COMPLÈTE ET SÉCURISÉE DES COMPTEURS VISUELS
    setState(() { 
      _isRunning = false; 
      _seconds = 0; 
      // Égaliser les deux variables fait tomber (_steps - _baseSteps) instantanément à 0
      _baseSteps = _steps; 
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Activité enregistrée ! Compteurs réinitialisés.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: kNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(children: [
                _buildStatsRow(),
                const SizedBox(height: 16),
                _buildInfoChips(),
                const SizedBox(height: 16),
                _buildStatusBar(),
                const SizedBox(height: 24),
                _buildControls(),
                const SizedBox(height: 24),
                _buildWeeklyChart(),
                const SizedBox(height: 16),
                _buildTipCard(),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        _circleButton(
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kNavy),
          onTap: () => Navigator.of(context).maybePop(),
        ),
        Expanded(child: Text('Activité sportive',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w600, color: kNavy))),
        const SizedBox(width: 36),
      ]),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(children: [
      Expanded(child: _buildRingCard(
        percent: (_currentSteps / 10000).clamp(0.0, 1.0),
        value: '$_currentSteps', unit: 'pas',
        icon: Icons.directions_walk_rounded,
        ringColor: kNavy, ringBgColor: kRingBg, label: 'Pas effectués',
      )),
      const SizedBox(width: 14),
      Expanded(child: _buildRingCard(
        percent: (_currentMin / 60).clamp(0.0, 1.0),
        value: '$_currentMin', unit: 'min',
        icon: Icons.timer_rounded,
        ringColor: kOrange, ringBgColor: kOrangeBg, label: 'Durée',
      )),
    ]);
  }

  Widget _buildRingCard({
    required double percent, required String value, required String unit,
    required IconData icon, required Color ringColor,
    required Color ringBgColor, required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(children: [
        CircularPercentIndicator(
          radius: 52.0, lineWidth: 8.0, percent: percent,
          backgroundColor: ringBgColor, progressColor: ringColor,
          circularStrokeCap: CircularStrokeCap.round,
          center: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: ringColor, size: 18),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w700, color: kNavy, height: 1.1)),
            Text(unit, style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: kTextMuted, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: kTextMuted, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Info chips ────────────────────────────────────────────────────
  Widget _buildInfoChips() {
    return Row(children: [
      Expanded(child: _buildChip(_km.toStringAsFixed(1), 'km')),
      const SizedBox(width: 10),
      Expanded(child: _buildChip('$_kcal', 'kcal')),
      const SizedBox(width: 10),
      Expanded(child: _buildChip(_kmh.toStringAsFixed(1), 'km/h')),
    ]);
  }

  Widget _buildChip(String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(children: [
        Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700, color: kNavy)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 10, color: kTextMuted)),
      ]),
    );
  }

  // ── Status bar ────────────────────────────────────────────────────
  Widget _buildStatusBar() {
    final dotColor   = _isRunning ? kGreen : kOrange;
    final statusText = _isRunning ? 'En cours...' : 'En pause';
    final timeStr    =
        '${_currentMin.toString().padLeft(2, '0')}:${_currentSec.toString().padLeft(2, '0')}';
    return Container(
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(statusText, style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: kNavy)),
        const Spacer(),
        Text(timeStr, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: kTextMuted)),
      ]),
    );
  }

  // ── Controls ──────────────────────────────────────────────────────
  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCtrlButton(
          icon: Icons.pause_rounded, bgColor: kOrangeBg,
          iconColor: kOrange, borderColor: kOrange,
          label: 'Pause', size: 56,
          onTap: _isRunning ? _pause : null,
        ),
        const SizedBox(width: 20),
        _buildCtrlButton(
          icon: Icons.play_arrow_rounded, bgColor: kNavy,
          iconColor: Colors.white, borderColor: kNavy,
          label: _isRunning ? 'En cours' : 'Démarrer',
          size: 68, iconSize: 30,
          onTap: _isRunning ? null : (_seconds > 0 ? _resume : _start),
        ),
        const SizedBox(width: 20),
        _buildCtrlButton(
          icon: Icons.stop_rounded, bgColor: kRedBg,
          iconColor: kRed, borderColor: kRed,
          label: 'Terminer', size: 56,
          onTap: (_isRunning || _seconds > 0) ? _finish : null, // Grisé si aucune activité n'a démarré
        ),
      ],
    );
  }

  Widget _buildCtrlButton({
    required IconData icon, required Color bgColor,
    required Color iconColor, required Color borderColor,
    required String label, required double size,
    double iconSize = 22, VoidCallback? onTap,
  }) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1.0,
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              color: bgColor, shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 11, color: kTextMuted, fontWeight: FontWeight.w500)),
    ]);
  }

  // ── Weekly Steps Bar Chart ─────────────────────────────────────────
  Widget _buildWeeklyChart() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = _weeklySteps.isEmpty
        ? 10000.0
        : (_weeklySteps.reduce((a, b) => a > b ? a : b) * 1.25)
            .clamp(2500, 15000)
            .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STEPS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: kTextMuted, letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _weeklyLoading
              ? const SizedBox(height: 180,
                  child: Center(child: CircularProgressIndicator(color: kNavy, strokeWidth: 2)))
              : SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY: maxVal,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxVal / 4,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: kBorder, strokeWidth: 0.8),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: maxVal / 4,
                            reservedSize: 42,
                            getTitlesWidget: (v, _) => Text(
                              _formatYLabel(v),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10, color: kTextMuted),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              final isToday = i == _todayIndex;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(days[i],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: isToday
                                        ? FontWeight.w700 : FontWeight.w400,
                                    color: isToday ? kBarToday : kTextMuted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(7, (i) {
                        final isToday = i == _todayIndex;
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: _weeklySteps[i],
                            color: isToday ? kBarToday : kBarColor,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true, toY: maxVal, color: kBackground,
                            ),
                          ),
                        ]);
                      }),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => kNavy,
                          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                            '${rod.toY.toInt()} pas',
                            GoogleFonts.plusJakartaSans(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _formatYLabel(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k == k.floorToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return v.toInt().toString();
  }

  // ── Tip card ──────────────────────────────────────────────────────
  Widget _buildTipCard() {
    return Container(
      decoration: BoxDecoration(
          color: kInfoBg, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Continuez votre effort, vous êtes sur la bonne voie !',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: kNavy, height: 1.5),
          )),
        ],
      ),
    );
  }

  // ── Helper ────────────────────────────────────────────────────────
  Widget _circleButton({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: kCardBg, shape: BoxShape.circle,
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}