import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../app_colors.dart';
import 'add_meal_screen.dart';
import 'nutrition_screen.dart';
import 'history_screen.dart';
import 'sport_screen.dart';
import 'glycemie_screen.dart';

// ─────────────────────────────────────────
// Dashboard Screen
// ─────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  String _userName = 'Utilisateur';
  String? _userEmail;

  // Nutrition data (DYNAMIC from Firestore)
  int _totalCaloriesToday = 0;
  int _totalSugarToday = 0;
  int _mealsCountToday = 0;
  bool _loadingStats = true;

  // Weekly data
  List<_DayInsight> _weeklyNutritionData = [];
  bool _loadingWeeklyData = true;

  Uint8List? _profileImageBytes;

  // Stream subscriptions
  StreamSubscription? _todaySubscription;
  StreamSubscription? _weeklySubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayStats();
    _loadWeeklyNutritionData();
  }

  @override
  void dispose() {
    _todaySubscription?.cancel();
    _weeklySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _userEmail = user.email;
      _userName = user.displayName ?? user.email?.split('@').first ?? 'Utilisateur';
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] ?? _userName;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _loadTodayStats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingStats = false);
      return;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    _todaySubscription?.cancel();
    _todaySubscription = FirebaseFirestore.instance
        .collection('meals')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp1', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp1', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen((snapshot) {
      int totalCal = 0;
      int totalSugar = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalCal += (data['calories'] as num?)?.toInt() ?? 0;
        totalSugar += (data['glucides'] as num?)?.toInt() ?? 0;
      }

      if (mounted) {
        setState(() {
          _totalCaloriesToday = totalCal;
          _totalSugarToday = totalSugar;
          _mealsCountToday = snapshot.docs.length;
          _loadingStats = false;
        });
      }
    }, onError: (e) {
      debugPrint('Error loading today stats: $e');
      if (mounted) setState(() => _loadingStats = false);
    });
  }

  void _loadWeeklyNutritionData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loadingWeeklyData = false;
        _weeklyNutritionData = _getDefaultWeekData();
      });
      return;
    }

    setState(() => _loadingWeeklyData = true);

    // Chercher le premier repas
    FirebaseFirestore.instance
        .collection('meals')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp1', descending: false)
        .limit(1)
        .get()
        .then((firstMealSnapshot) {
      DateTime startDate;
      final now = DateTime.now();
      
      if (firstMealSnapshot.docs.isNotEmpty) {
        // Si un repas existe, commencer à partir du premier repas
        final firstMeal = firstMealSnapshot.docs.first.data();
        final firstMealDate = (firstMeal['timestamp1'] as Timestamp).toDate();
        startDate = DateTime(firstMealDate.year, firstMealDate.month, firstMealDate.day);
      } else {
        // Si aucun repas, commencer à partir d'il y a 7 jours
        startDate = DateTime(now.year, now.month, now.day - 6);
      }
      
      final endDate = DateTime(startDate.year, startDate.month, startDate.day + 7);

      _weeklySubscription?.cancel();
      _weeklySubscription = FirebaseFirestore.instance
          .collection('meals')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp1', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp1', isLessThan: Timestamp.fromDate(endDate))
          .snapshots()
          .listen((querySnapshot) {
        final daysOfWeek = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        
        // Construire les 7 jours à partir de startDate
        Map<String, _DayInsight> dailyMap = {};
        
        for (int i = 0; i < 7; i++) {
          final date = DateTime(startDate.year, startDate.month, startDate.day + i);
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final dayName = daysOfWeek[date.weekday - 1];
          
          // Valeurs statiques pour glycémie et sport
          final Map<String, double> staticGlycemie = {
            'Lun': 8.2, 'Mar': 7.6, 'Mer': 7.1, 'Jeu': 6.8,
            'Ven': 7.0, 'Sam': 7.8, 'Dim': 7.3,
          };
          final Map<String, int> staticSport = {
            'Lun': 10, 'Mar': 30, 'Mer': 45, 'Jeu': 60,
            'Ven': 40, 'Sam': 15, 'Dim': 35,
          };
          
          dailyMap[dateKey] = _DayInsight(
            day: dayName,
            glycemie: staticGlycemie[dayName] ?? 7.0,
            glucides: 0,
            sportMin: staticSport[dayName] ?? 20,
          );
        }

        // Lecture des glucides
        debugPrint('📄 Nombre de repas trouvés: ${querySnapshot.docs.length}');
        debugPrint('📅 Période: $startDate à $endDate');
        
        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final timestamp = (data['timestamp1'] as Timestamp).toDate();
          final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
          final glucides = (data['glucides'] as num?)?.toInt() ?? 0;
          
          debugPrint('📝 Repas: ${data['name']}, DateKey: $dateKey, Glucides: $glucides');

          if (dailyMap.containsKey(dateKey)) {
            final existing = dailyMap[dateKey]!;
            dailyMap[dateKey] = _DayInsight(
              day: existing.day,
              glycemie: existing.glycemie,
              glucides: existing.glucides + glucides,
              sportMin: existing.sportMin,
            );
          }
        }

        // Reconstruction dans l'ordre chronologique (de startDate à 7 jours)
        final List<_DayInsight> combinedData = [];
        for (int i = 0; i < 7; i++) {
          final date = DateTime(startDate.year, startDate.month, startDate.day + i);
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          combinedData.add(dailyMap[dateKey]!);
        }

        debugPrint('📊 Glucides par jour: ${combinedData.map((d) => '${d.day}:${d.glucides}g').join(', ')}');

        if (mounted) {
          setState(() {
            _weeklyNutritionData = combinedData;
            _loadingWeeklyData = false;
          });
        }
      }, onError: (e) {
        debugPrint('Error loading weekly data: $e');
        if (mounted) {
          setState(() {
            _weeklyNutritionData = _getDefaultWeekData();
            _loadingWeeklyData = false;
          });
        }
      });
    }).catchError((e) {
      debugPrint('Error getting first meal: $e');
      if (mounted) {
        setState(() {
          _weeklyNutritionData = _getDefaultWeekData();
          _loadingWeeklyData = false;
        });
      }
    });
  }

  List<_DayInsight> _getDefaultWeekData() {
    return [
      _DayInsight(day: 'Lun', glycemie: 8.2, glucides: 0, sportMin: 10),
      _DayInsight(day: 'Mar', glycemie: 7.6, glucides: 0, sportMin: 30),
      _DayInsight(day: 'Mer', glycemie: 7.1, glucides: 0, sportMin: 45),
      _DayInsight(day: 'Jeu', glycemie: 6.8, glucides: 0, sportMin: 60),
      _DayInsight(day: 'Ven', glycemie: 7.0, glucides: 0, sportMin: 40),
      _DayInsight(day: 'Sam', glycemie: 7.8, glucides: 0, sportMin: 15),
      _DayInsight(day: 'Dim', glycemie: 7.3, glucides: 0, sportMin: 35),
    ];
  }

  Future<void> _pickProfileImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 300,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _profileImageBytes = bytes);
  }

  Future<void> _signOut() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Déconnecter',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _goToAddMeal() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddMealScreen()));
  }

  List<Widget> get _pages => [
        _HomeTab(
          userName: _userName,
          totalCalories: _totalCaloriesToday,
          totalSugar: _totalSugarToday,
          mealsCount: _mealsCountToday,
          loading: _loadingStats,
          weeklyData: _weeklyNutritionData,
          loadingWeekly: _loadingWeeklyData,
          onAddMeal: _goToAddMeal,
        ),
        const NutritionScreen(),
        const SportScreen(),
        const GlycemieScreen(),
        const HistoryScreen(),
        _ProfileTab(
          userName: _userName,
          userEmail: _userEmail,
          profileImageBytes: _profileImageBytes,
          onPickImage: _pickProfileImage,
          onSignOut: _signOut,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8)),
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GNav(
              rippleColor: AppColors.primary.withOpacity(0.2),
              hoverColor: AppColors.primary.withOpacity(0.1),
              gap: 8,
              activeColor: AppColors.white,
              iconSize: 24,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppColors.primary,
              color: AppColors.textGrey,
              textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.white),
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                HapticFeedback.lightImpact();
                setState(() => _currentIndex = index);
              },
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Accueil'),
                GButton(icon: Icons.restaurant_menu_rounded, text: 'Nutrition'),
                GButton(icon: Icons.directions_run_rounded, text: 'Sport'),
                GButton(icon: Icons.bloodtype_rounded, text: 'Glycémie'),
                GButton(icon: Icons.history_rounded, text: 'Historique'),
                GButton(icon: Icons.person_rounded, text: 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Home Tab
// ═══════════════════════════════════════════════════════════════

class _HomeTab extends StatelessWidget {
  final String userName;
  final int totalCalories;
  final int totalSugar;
  final int mealsCount;
  final bool loading;
  final List<_DayInsight> weeklyData;
  final bool loadingWeekly;
  final VoidCallback onAddMeal;

  const _HomeTab({
    required this.userName,
    required this.totalCalories,
    required this.totalSugar,
    required this.mealsCount,
    required this.loading,
    required this.weeklyData,
    required this.loadingWeekly,
    required this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => onAddMeal(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.4),
                            width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          userName.isNotEmpty
                              ? userName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats Today
              if (loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator()))
              else
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Calories',
                            value: '$totalCalories',
                            unit: 'kcal',
                            color: AppColors.calories)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatCard(
                            icon: Icons.water_drop_rounded,
                            label: 'Sucre',
                            value: '$totalSugar',
                            unit: 'g',
                            color: AppColors.sugar)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatCard(
                            icon: Icons.restaurant_rounded,
                            label: 'Repas',
                            value: '$mealsCount',
                            unit: '',
                            color: AppColors.primary)),
                  ],
                ),

              const SizedBox(height: 20),

              // Sugar warning
              if (!loading && totalSugar > 50)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.sugar.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.sugar.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.sugar),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Attention : votre consommation de sucre dépasse 50g aujourd\'hui.',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.sugar,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // Dashboard Insights Section
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Dashboard Insights',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('7 jours',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Weekly Insights
              if (loadingWeekly)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator()))
              else
                _WeeklyInsightsSection(weeklyData: weeklyData),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Weekly Insights Section
// ═══════════════════════════════════════════════

class _WeeklyInsightsSection extends StatelessWidget {
  final List<_DayInsight> weeklyData;

  const _WeeklyInsightsSection({required this.weeklyData});

  double get _avgGlycemie {
    if (weeklyData.isEmpty) return 0;
    return weeklyData.map((e) => e.glycemie).reduce((a, b) => a + b) /
        weeklyData.length;
  }

  int get _totalSportMin {
    if (weeklyData.isEmpty) return 0;
    return weeklyData.map((e) => e.sportMin).reduce((a, b) => a + b);
  }

  int get _totalGlucides {
    if (weeklyData.isEmpty) return 0;
    return weeklyData.map((e) => e.glucides).reduce((a, b) => a + b);
  }

  String get _autoInsight {
    if (weeklyData.isEmpty) return '';

    final sportDays = weeklyData.where((d) => d.sportMin >= 30).toList();
    if (sportDays.isEmpty) return '';
    final avgGlyWithSport =
        sportDays.map((e) => e.glycemie).reduce((a, b) => a + b) /
            sportDays.length;

    final noSportDays = weeklyData.where((d) => d.sportMin < 30).toList();
    if (noSportDays.isEmpty) return '';
    final avgGlyNoSport =
        noSportDays.map((e) => e.glycemie).reduce((a, b) => a + b) /
            noSportDays.length;

    if (avgGlyWithSport < avgGlyNoSport) {
      return '📉 Les jours avec +30 min de sport, votre glycémie moyenne était plus basse (${avgGlyWithSport.toStringAsFixed(1)} vs ${avgGlyNoSport.toStringAsFixed(1)} mmol/L).';
    } else {
      return '📈 Des apports élevés en glucides semblent associés à une augmentation de votre glycémie.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 3 Summary Cards
        Row(
          children: [
            _InsightSummaryCard(
                icon: '🩸',
                label: 'Glycémie moy.',
                value: _avgGlycemie.toStringAsFixed(1),
                unit: 'mmol/L',
                color: const Color(0xFFE74C3C)),
            const SizedBox(width: 10),
            _InsightSummaryCard(
                icon: '🏃',
                label: 'Sport total',
                value: '$_totalSportMin',
                unit: 'min',
                color: AppColors.primary),
            const SizedBox(width: 10),
            _InsightSummaryCard(
                icon: '🍞',
                label: 'Glucides',
                value: '$_totalGlucides',
                unit: 'g',
                color: const Color(0xFFE67E22)),
          ],
        ),

        const SizedBox(height: 20),

        // Correlation Chart
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Corrélation Glycémie · Glucides · Sport',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _LegendDot(
                      color: const Color(0xFFE74C3C),
                      label: 'Glycémie (mmol/L)'),
                  const SizedBox(width: 12),
                  _LegendDot(
                      color: const Color(0xFFE67E22),
                      label: 'Glucides (×10g)'),
                  const SizedBox(width: 12),
                  _LegendDot(
                      color: AppColors.primary, label: 'Sport (×10min)'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                  height: 180, child: _CorrelationChart(data: weeklyData)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Auto Insight
        if (_autoInsight.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withOpacity(0.08),
                AppColors.primary.withOpacity(0.03)
              ]),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 Observation automatique',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.3)),
                const SizedBox(height: 8),
                Text(_autoInsight,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                        height: 1.5)),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Recent History
        Text('Historique récent',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
        const SizedBox(height: 12),

        ...weeklyData.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          final isToday = i == weeklyData.length - 1;
          return _HistoryDayRow(insight: d, isToday: isToday);
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Model
// ═══════════════════════════════════════════════

class _DayInsight {
  final String day;
  final double glycemie;
  final int glucides;
  final int sportMin;
  const _DayInsight({
    required this.day,
    required this.glycemie,
    required this.glucides,
    required this.sportMin,
  });
}

// ═══════════════════════════════════════════════
// Widgets
// ═══════════════════════════════════════════════

class _InsightSummaryCard extends StatelessWidget {
  final String icon, label, value, unit;
  final Color color;
  const _InsightSummaryCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1)),
            Text(unit,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.7))),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey)),
      ],
    );
  }
}

class _CorrelationChart extends StatelessWidget {
  final List<_DayInsight> data;
  const _CorrelationChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth > 0 ? constraints.maxWidth : 400,
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: ['10', '8', '6', '4', '2', '0']
                      .map((v) => Text(v,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w600)))
                      .toList(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: CustomPaint(
                      painter: _ChartPainter(data: data),
                      child: const SizedBox.expand()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<_DayInsight> data;
  _ChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxVal = 10.0;
    double xStep = size.width / (data.length - 1);

    void drawCurve(List<double> values, Color color) {
      final path = Path();
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < values.length; i++) {
        final x = i * xStep;
        final y = size.height - (values[i] / maxVal * size.height);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevX = (i - 1) * xStep;
          final prevY =
              size.height - (values[i - 1] / maxVal * size.height);
          final cp1x = prevX + xStep / 3;
          final cp2x = x - xStep / 3;
          path.cubicTo(cp1x, prevY, cp2x, y, x, y);
        }
      }
      canvas.drawPath(path, paint);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final dotBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      for (int i = 0; i < values.length; i++) {
        final x = i * xStep;
        final y = size.height - (values[i] / maxVal * size.height);
        canvas.drawCircle(Offset(x, y), 5, dotBorder);
        canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      }
    }

    drawCurve(
        data.map((d) => d.glucides / 10.0).toList(), const Color(0xFFE67E22));
    drawCurve(
        data.map((d) => d.sportMin / 10.0).toList(), AppColors.primary);
    drawCurve(data.map((d) => d.glycemie).toList(), const Color(0xFFE74C3C));

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final textPainter = TextPainter(
        text: TextSpan(
            text: data[i].day,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888))),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height + 4));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => true;
}

class _HistoryDayRow extends StatelessWidget {
  final _DayInsight insight;
  final bool isToday;
  const _HistoryDayRow({required this.insight, required this.isToday});

  Color get _glycColor {
    if (insight.glycemie < 5.5) return const Color(0xFFE74C3C);
    if (insight.glycemie <= 13) return AppColors.primary;
    return const Color(0xFFE67E22);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary.withOpacity(0.06) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: AppColors.primary.withOpacity(0.2))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Text(insight.day,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textDark)),
                if (isToday)
                  Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: _HistoryPill(
                  icon: '🩸',
                  value: '${insight.glycemie} mmol',
                  color: _glycColor)),
          const SizedBox(width: 8),
          Expanded(
              child: _HistoryPill(
                  icon: '🍞',
                  value: '${insight.glucides}g',
                  color: const Color(0xFFE67E22))),
          const SizedBox(width: 8),
          Expanded(
              child: _HistoryPill(
                  icon: '🏃',
                  value: '${insight.sportMin}min',
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _HistoryPill extends StatelessWidget {
  final String icon, value;
  final Color color;
  const _HistoryPill(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Flexible(
              child: Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4)),
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          if (unit.isNotEmpty)
            Text(unit,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGrey)),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Profile Tab
// ─────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  final String userName;
  final String? userEmail;
  final Uint8List? profileImageBytes;
  final VoidCallback onPickImage;
  final VoidCallback onSignOut;

  const _ProfileTab(
      {required this.userName,
      required this.userEmail,
      required this.profileImageBytes,
      required this.onPickImage,
      required this.onSignOut});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isDiabetique = true;
  String _diabeteType = '';

  @override
  void initState() {
    super.initState();
    _loadDiabeteType();
  }

  Future<void> _loadDiabeteType() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _diabeteType = data['diabeteType'] ?? '';
          _isDiabetique = _diabeteType.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error loading diabetes type: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: widget.onPickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: widget.profileImageBytes != null
                        ? MemoryImage(widget.profileImageBytes!)
                        : null,
                    child: widget.profileImageBytes == null
                        ? Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 40,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.white, width: 2)),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.userName,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            if (widget.userEmail != null)
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(widget.userEmail!,
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textGrey, fontSize: 14))),
            if (_isDiabetique && _diabeteType.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_diabeteType,
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            const SizedBox(height: 24),
            if (_isDiabetique)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle),
                          child: Icon(Icons.people_outline_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Accompagnant',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textDark)),
                              Text('Invitez quelqu\'un à vous suivre',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushNamed(context, '/add-companion');
                        },
                        icon: const Icon(Icons.person_add_alt_1_rounded,
                            size: 18),
                        label: const Text('Ajouter un accompagnant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
                icon: Icons.person_outline_rounded,
                label: 'Mon profil',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/profile');
                }),
            _ProfileMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/notifications');
                }),
            _ProfileMenuItem(
                icon: Icons.lock_outline_rounded,
                label: 'Sécurité',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/securite');
                }),
            _ProfileMenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Aide',
                onTap: () {
                  HapticFeedback.lightImpact();
                }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Déconnexion',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileMenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500, color: AppColors.textDark)),
        trailing:
            Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}