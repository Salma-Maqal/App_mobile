// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../app_colors.dart';
import 'add_meal_screen.dart';
import 'nutrition_screen.dart';
import 'historique_screen.dart';

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

  // ── user info ──
  String _userName = 'Utilisateur';
  String? _userEmail;

  // ── meal summary ──
  int _totalCaloriesToday = 0;
  int _totalSugarToday = 0;
  int _mealsCountToday = 0;
  bool _loadingStats = true;

  // ── profile photo ──
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayStats();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement du profil'), backgroundColor: AppColors.error),
        );
      }
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

    final stream = FirebaseFirestore.instance
        .collection('meals')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();

    stream.listen((snapshot) {
      int totalCal = 0;
      int totalSugar = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalCal += (data['calories'] as num?)?.toInt() ?? 0;
        totalSugar += (data['sugar'] as num?)?.toInt() ?? 0;
      }

      if (mounted) {
        setState(() {
          _totalCaloriesToday = totalCal;
          _totalSugarToday = totalSugar;
          _mealsCountToday = snapshot.docs.length;
          _loadingStats = false;
        });
      }
    }, onError: (error) {
      debugPrint('Error loading stats: $error');
      if (mounted) {
        setState(() => _loadingStats = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de chargement des statistiques'), backgroundColor: AppColors.error),
        );
      }
    });
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
      context,
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );
  }

  late final List<Widget> _pages = [
    _HomeTab(
      userName: _userName,
      totalCalories: _totalCaloriesToday,
      totalSugar: _totalSugarToday,
      mealsCount: _mealsCountToday,
      loading: _loadingStats,
      onAddMeal: _goToAddMeal,
      onGoNutrition: () => setState(() => _currentIndex = 1),
    ),
    const NutritionScreen(),
    const _HistoryTab(),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // ── Floating Navigation Bar (Medical Premium Style) ──
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppColors.primary,
              color: AppColors.textGrey,
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.white,
              ),
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                HapticFeedback.lightImpact();
                setState(() => _currentIndex = index);
              },
              tabs: const [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Accueil',
                ),
                GButton(
                  icon: Icons.restaurant_menu_rounded,
                  text: 'Nutrition',
                ),
                GButton(
                  icon: Icons.history_rounded,
                  text: 'Historique',
                ),
                GButton(
                  icon: Icons.person_rounded,
                  text: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 🏠 Home Tab - Medical Premium Design
// ─────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final String userName;
  final int totalCalories;
  final int totalSugar;
  final int mealsCount;
  final bool loading;
  final VoidCallback onAddMeal;
  final VoidCallback onGoNutrition;

  const _HomeTab({
    required this.userName,
    required this.totalCalories,
    required this.totalSugar,
    required this.mealsCount,
    required this.loading,
    required this.onAddMeal,
    required this.onGoNutrition,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Modern Header ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour 👋',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textGrey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Prêt pour un nouveau suivi ?',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats Today ──
            Text('Aujourd\'hui',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),

            if (widget.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Calories',
                    value: '${widget.totalCalories}',
                    unit: 'kcal',
                    color: AppColors.calories,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _StatCard(
                    icon: Icons.water_drop_rounded,
                    label: 'Sucre',
                    value: '${widget.totalSugar}',
                    unit: 'g',
                    color: AppColors.sugar,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _StatCard(
                    icon: Icons.restaurant_rounded,
                    label: 'Repas',
                    value: '${widget.mealsCount}',
                    unit: '',
                    color: AppColors.primary,
                  )),
                ],
              ),

            const SizedBox(height: 28),

            // ── Sugar warning (medical alert style) ──
            if (!widget.loading && widget.totalSugar > 50)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.sugar.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sugar.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.sugar),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Attention : votre consommation de sucre dépasse 50g aujourd\'hui.',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppColors.sugar, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Modern Calendar Section ──
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2026, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  HapticFeedback.lightImpact();
                },
                calendarFormat: CalendarFormat.week,
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: GoogleFonts.plusJakartaSans(
                    color: AppColors.sugar,
                  ),
                  defaultTextStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  selectedTextStyle: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                  weekendStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.sugar,
                  ),
                ),
              ),
            ),

            // ── Quick Actions Title ──
            Text('Actions rapides',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),

            // ── Modern Action Cards (Medical Premium Colors) ──
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _ActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Ajouter Repas',
                  color: AppColors.primary,
                  onTap: widget.onAddMeal,
                ),
                _ActionCard(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Sport',
                  color: AppColors.sport,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/sport');
                  },
                ),
                _ActionCard(
                  icon: Icons.bloodtype_outlined,
                  label: 'Glycémie',
                  color: AppColors.accent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/glycemie');
                  },
                ),
                _ActionCard(
                  icon: Icons.water_drop_outlined,
                  label: 'Hydratation',
                  color: AppColors.water,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/hydratation');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Modern Action Card Component
// ─────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 📊 History Tab
// ─────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) => const HistoriqueScreen();
}

// ─────────────────────────────────────────
// 👤 Profile Tab
// ─────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  final String userName;
  final String? userEmail;
  final Uint8List? profileImageBytes;
  final VoidCallback onPickImage;
  final VoidCallback onSignOut;

  const _ProfileTab({
    required this.userName,
    required this.userEmail,
    required this.profileImageBytes,
    required this.onPickImage,
    required this.onSignOut,
  });

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
            // ── Avatar ──
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
                                fontWeight: FontWeight.bold),
                          )
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
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
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
                    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            if (widget.userEmail != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.userEmail!,
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textGrey, fontSize: 14)),
              ),
            if (_isDiabetique && _diabeteType.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_diabeteType,
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),

            const SizedBox(height: 24),

            // ── Ajouter Accompagnant ──
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
                            shape: BoxShape.circle,
                          ),
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
                                      fontSize: 12,
                                      color: AppColors.textGrey)),
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

            // ── Menu items ──
            _ProfileMenuItem(
              icon: Icons.person_outline_rounded,
              label: 'Mon profil',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/profile');
              },
            ),
            _ProfileMenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            _ProfileMenuItem(
              icon: Icons.lock_outline_rounded,
              label: 'Sécurité',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/securite');
              },
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Aide',
              onTap: () {
                HapticFeedback.lightImpact();
              },
            ),

            const SizedBox(height: 20),

            // ── Sign out ──
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

// ─────────────────────────────────────────
// ── Reusable Widgets - Medical Premium Style
// ─────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

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
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: AppColors.textDark)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}