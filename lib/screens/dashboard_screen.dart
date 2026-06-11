import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../app_colors.dart';
import 'nutrition_screen.dart';
import 'history_screen.dart';
import 'sport_screen.dart';
import 'glycemie_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _userName = 'Utilisateur';
  int _totalCaloriesToday = 0;
  int _totalSugarToday = 0;
  int _mealsCountToday = 0;
  bool _loadingStats = true;
  List<_DayInsight> _weeklyNutritionData = [];
  bool _loadingWeeklyData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayStats();
    _loadWeeklyNutritionData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() => _userName = doc.data()?['name'] ?? user.displayName ?? 'Utilisateur');
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  void _loadTodayStats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loadingStats = false); return; }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    FirebaseFirestore.instance.collection('meals')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp1', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp1', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots().listen((snapshot) {
      int totalCal = 0, totalSugar = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalCal += (data['calories'] as num?)?.toInt() ?? 0;
        totalSugar += (data['glucides'] as num?)?.toInt() ?? 0;
      }
      if (mounted) setState(() { _totalCaloriesToday = totalCal; _totalSugarToday = totalSugar; _mealsCountToday = snapshot.docs.length; _loadingStats = false; });
    });
  }

  void _loadWeeklyNutritionData() {
    // ضعي هنا منطق جلب البيانات الأسبوعية الخاص بك
    setState(() { _weeklyNutritionData = []; _loadingWeeklyData = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _currentIndex, children: [
        _HomeTab(userName: _userName, totalCalories: _totalCaloriesToday, totalSugar: _totalSugarToday, mealsCount: _mealsCountToday, loading: _loadingStats, weeklyData: _weeklyNutritionData, loadingWeekly: _loadingWeeklyData),
        const NutritionScreen(),
        const SportScreen(),
        const GlycemieScreen(),
        const HistoryScreen(),
        // يمكنكِ إضافة ProfileTab هنا
      ]),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GNav(
            activeColor: AppColors.white, tabBackgroundColor: AppColors.primary, color: AppColors.textGrey,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            selectedIndex: _currentIndex,
            onTabChange: (index) => setState(() => _currentIndex = index),
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
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userName;
  final int totalCalories, totalSugar, mealsCount;
  final bool loading;
  final List<_DayInsight> weeklyData;
  final bool loadingWeekly;

  const _HomeTab({required this.userName, required this.totalCalories, required this.totalSugar, required this.mealsCount, required this.loading, required this.weeklyData, required this.loadingWeekly});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName, style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 20),
            if (loading) const Center(child: CircularProgressIndicator())
            else Row(
              children: [
                Expanded(child: _StatCard(icon: Icons.local_fire_department_rounded, label: 'Calories', value: '$totalCalories', unit: 'kcal', color: AppColors.calories)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.water_drop_rounded, label: 'Sucre', value: '$totalSugar', unit: 'g', color: AppColors.sugar)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.restaurant_rounded, label: 'Repas', value: '$mealsCount', unit: '', color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 20),
            Text('Dashboard Insights', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 14),
            if (loadingWeekly) const Center(child: CircularProgressIndicator())
            else _WeeklyInsightsSection(weeklyData: weeklyData),
          ],
        ),
      ),
    );
  }
}