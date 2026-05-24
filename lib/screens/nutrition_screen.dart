import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_meal_screen.dart';

// ─────────────────────────────────────────────
// COULEURS
// ─────────────────────────────────────────────
const _kPurple  = Color(0xFF6C5CE7);
const _kPurple2 = Color(0xFFA29BFE);
const _kOrange  = Color(0xFFFF9F43);
const _kGreen   = Color(0xFF10AC84);
const _kDark    = Color(0xFF222F3E);
const _kTextMuted = Color(0xFF8395A7);
const _kBg      = Color(0xFFF4F6FB); 

// ─────────────────────────────────────────────
// MODÈLE
// ─────────────────────────────────────────────
class _MealSlot {
  final String imagePath;
  final String name;
  final String mealType;
  final String recommended;

  const _MealSlot({
    required this.imagePath,
    required this.name,
    required this.mealType,
    required this.recommended, // Paramètre requis
  });
}

// ✅ FIX : Ajout du champ 'recommended' manquant sur la ligne du 'Snack'
const _slots = [
  _MealSlot(
    imagePath: 'assets/typeRepas/breakfast.jpg',
    name: 'Breakfast',
    mealType: 'petit-dejeuner',
    recommended: 'Recommended 830–1170 Cal',
  ),
  _MealSlot(
    imagePath: 'assets/typeRepas/lunch.jpg',
    name: 'Lunch',
    mealType: 'dejeuner',
    recommended: 'Recommended 255–370 Cal',
  ),
  _MealSlot(
    imagePath: 'assets/typeRepas/snack.jpg',
    name: 'Snack',
    mealType: 'collation',
    recommended: 'Recommended 150–250 Cal', // Fixé ici !
  ),
  _MealSlot(
    imagePath: 'assets/typeRepas/dinner2.jpg',
    name: 'Dinner',
    mealType: 'diner',
    recommended: 'Recommended 255–370 Cal',
  ),
];

// ─────────────────────────────────────────────
// NutritionScreen
// ─────────────────────────────────────────────
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final Map<String, List<Map<String, dynamic>>> _todayMeals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end   = start.add(const Duration(days: 1));

      final snap = await FirebaseFirestore.instance
          .collection('meals')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: false)
          .get();

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final doc in snap.docs) {
        final d    = doc.data();
        final type = (d['mealType'] as String?) ?? 'repas';
        grouped.putIfAbsent(type, () => []).add(d);
      }
      if (mounted) {
        setState(() {
          _todayMeals
            ..clear()
            ..addAll(grouped);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalCalories => _todayMeals.values
      .expand((l) => l)
      .fold(0, (s, m) => s + ((m['calories'] as num?)?.toInt() ?? 0));

  void _goAddMeal() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddMealScreen()));
    _loadToday(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            if (_totalCalories > 0) _buildCalorieBanner(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _kPurple))
                  : RefreshIndicator(
                      color: _kPurple,
                      backgroundColor: Colors.white,
                      onRefresh: _loadToday,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                        itemCount: _slots.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, i) => _MealSlotCard(
                          slot: _slots[i],
                          entries: _todayMeals[_slots[i].mealType] ?? [],
                          onAdd: _goAddMeal,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: _kDark, size: 26),
            ),
            const Expanded(
              child: Text(
                'Nutrition',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kDark),
              ),
            ),
            const SizedBox(width: 26),
          ],
        ),
      );

  Widget _buildCalorieBanner() => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              '$_totalCalories Cal consumed today',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDark),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────
// _MealSlotCard
// ─────────────────────────────────────────────
class _MealSlotCard extends StatelessWidget {
  final _MealSlot slot;
  final List<Map<String, dynamic>> entries;
  final VoidCallback onAdd;

  const _MealSlotCard({
    required this.slot,
    required this.entries,
    required this.onAdd,
  });

  int get _totalCal => entries.fold(0, (s, e) => s + ((e['calories'] as num?)?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _kDark,
                            letterSpacing: -0.5,
                      ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entries.isEmpty ? slot.recommended : '$_totalCal Cal consumed',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kTextMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                            decoration: BoxDecoration(
                              color: _kPurple,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPurple.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: const Text(
                              '+ Add',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Transform.translate(
                    offset: const Offset(15, 0),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(slot.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (entries.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Colors.grey.shade100, thickness: 1.5),
            ),
            Column(
              children: entries.map((e) => _EntryRow(entry: e)).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _EntryRow
// ─────────────────────────────────────────────
class _EntryRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final emoji    = (entry['emoji']     as String?) ?? '🍽️';
    final name     = (entry['name']      as String?) ?? 'Meal';
    final portions = (entry['portions']  as num?)?.toInt() ?? 1;
    final cal      = (entry['calories']  as num?)?.toInt() ?? 0;
    final gluc     = (entry['glucides']  as num?)?.toInt() ?? 0;
    final prot     = (entry['proteines'] as num?)?.toInt() ?? 0;
    final lip      = (entry['lipides']   as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$name × $portions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kDark),
                ),
              ),
              Text(
                '$cal kcal',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniMacro(label: 'C', value: gluc, color: _kPurple),
              const SizedBox(width: 6),
              _MiniMacro(label: 'P', value: prot, color: _kOrange),
              const SizedBox(width: 6),
              _MiniMacro(label: 'F', value: lip,  color: _kGreen),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniMacro({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${value}g',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}