// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final _navKey = GlobalKey<CurvedNavigationBarState>();

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

  // ────────────────────────────────────────
  // Load user info from Firestore
  // ────────────────────────────────────────
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
    } catch (_) {}
  }

  // ────────────────────────────────────────
  // Load today's meal stats from Firestore
  // ────────────────────────────────────────
  Future<void> _loadTodayStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingStats = false);
      return;
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('meals')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

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
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // ────────────────────────────────────────
  // Pick profile photo
  // ────────────────────────────────────────
  Future<void> _pickProfileImage() async {
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

  // ────────────────────────────────────────
  // Sign out
  // ────────────────────────────────────────
  Future<void> _signOut() async {
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
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ────────────────────────────────────────
  // Navigate to Add Meal
  // ────────────────────────────────────────
  Future<void> _goToAddMeal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );
    _loadTodayStats(); // refresh stats after adding meal
  }

  // ────────────────────────────────────────
  // Pages
  // ────────────────────────────────────────
  late final List<Widget> _pages = [
    _HomeTab(
      userName: _userName,
      totalCalories: _totalCaloriesToday,
      totalSugar: _totalSugarToday,
      mealsCount: _mealsCountToday,
      loading: _loadingStats,
      onAddMeal: _goToAddMeal,
      onGoNutrition: () => _navKey.currentState?.setPage(1),
    ),
    const NutritionScreen(),
    _HistoryTab(),
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
      bottomNavigationBar: CurvedNavigationBar(
        key: _navKey,
        index: _currentIndex,
        height: 60,
        color: AppColors.primary,
        backgroundColor: AppColors.bg,
        buttonBackgroundColor: AppColors.darkMoss,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          Icon(Icons.home_rounded, size: 28, color: Colors.white),
          Icon(Icons.restaurant_menu_rounded, size: 28, color: Colors.white),
          Icon(Icons.history_rounded, size: 28, color: Colors.white),
          Icon(Icons.person_rounded, size: 28, color: Colors.white),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 🏠 Home Tab
// ─────────────────────────────────────────
class _HomeTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour 👋',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textGrey)),
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Stats Today ──
            Text('Aujourd\'hui',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),

            loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Calories',
                        value: '$totalCalories',
                        unit: 'kcal',
                        color: Colors.deepOrange,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        icon: Icons.water_drop_rounded,
                        label: 'Sucre',
                        value: '$totalSugar',
                        unit: 'g',
                        color: Colors.blue,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        icon: Icons.restaurant_rounded,
                        label: 'Repas',
                        value: '$mealsCount',
                        unit: '',
                        color: Colors.green,
                      )),
                    ],
                  ),

            const SizedBox(height: 28),

            // ── Sugar warning ──
            if (!loading && totalSugar > 50)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Attention : votre consommation de sucre dépasse 50g aujourd\'hui.',
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Quick Actions ──
            Text('Actions rapides',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2D2060))),
            const SizedBox(height: 12),

            // Row 1: Ajouter Repas + Sport
            Row(
              children: [
                Expanded(
                  child: _GradientActionButton(
                    emoji: '➕',
                    label: 'Ajouter Repas',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    onTap: onAddMeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GradientActionButton(
                    emoji: '🏃',
                    label: 'Sport 🏆',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFD9B71), Color(0xFFE17055)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/sport'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Glycémie + Eau
            Row(
              children: [
                Expanded(
                  child: _GradientActionButton(
                    emoji: '🩸',
                    label: 'Glycémie',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFEAA7), Color(0xFFFDCB6E)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    labelColor: const Color(0xFF7C5C00),
                    onTap: () => Navigator.pushNamed(context, '/glycemie'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GradientActionButton(
                    emoji: '💧',
                    label: 'Eau',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/hydratation'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: Historique (full width)
            _GradientActionButton(
              emoji: '📊',
              label: 'Historique',
              gradient: const LinearGradient(
                colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              fullWidth: true,
              onTap: () => Navigator.pushNamed(context, '/historique'),
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
// _HistoryTab → embed HistoriqueScreen directement
class _HistoryTab extends StatelessWidget {
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
  bool _isDiabetique = true; // loaded from Firestore
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
          .collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _diabeteType = data['diabeteType'] ?? '';
          // User is diabetique if diabeteType is set (not empty = diabetique patient)
          _isDiabetique = _diabeteType.isNotEmpty;
        });
      }
    } catch (_) {}
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
                            style: TextStyle(
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
                        border: Border.all(color: Colors.white, width: 2),
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
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            if (widget.userEmail != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.userEmail!,
                    style: TextStyle(
                        color: AppColors.textGrey, fontSize: 14)),
              ),
            if (_isDiabetique && _diabeteType.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_diabeteType,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),

            const SizedBox(height: 24),

            // ── Ajouter Accompagnant (uniquement pour les diabétiques) ──
            if (_isDiabetique)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.c2, AppColors.c1],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.c3),
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
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textDark)),
                              Text('Invitez quelqu\'un à vous suivre',
                                  style: TextStyle(
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
                        onPressed: () =>
                            Navigator.pushNamed(context, '/add-companion'),
                        icon: const Icon(Icons.person_add_alt_1_rounded,
                            size: 18),
                        label: const Text('Ajouter un accompagnant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
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
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            _ProfileMenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
            _ProfileMenuItem(
              icon: Icons.lock_outline_rounded,
              label: 'Sécurité',
              onTap: () => Navigator.pushNamed(context, '/securite'),
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Aide',
              onTap: () {},
            ),

            const SizedBox(height: 20),

            // ── Sign out ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text('Déconnexion',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
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
// ── Reusable Widgets
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(unit.isEmpty ? label : unit,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          if (unit.isNotEmpty)
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Gradient action button (new design)
// ─────────────────────────────────────────
class _GradientActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final Color? labelColor;
  final bool fullWidth;

  const _GradientActionButton({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.labelColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: labelColor ?? Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  final List<Map<String, dynamic>> _tips = const [
    {
      'icon': '🩸',
      'title': 'Contrôle glycémique',
      'text': 'Mangez à intervalles réguliers pour stabiliser votre glycémie.'
    },
    {
      'icon': '🥦',
      'title': 'Légumes recommandés',
      'text': 'Privilégiez les légumes verts à faible index glycémique.'
    },
    {
      'icon': '💧',
      'title': 'Hydratation',
      'text': 'Buvez au moins 1,5L d\'eau par jour pour aider les reins.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().hour % _tips.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.85),
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(tip['icon'] as String, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip['title'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(tip['text'] as String,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12)),
              ],
            ),
          ),
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
        color: Colors.white,
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
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}