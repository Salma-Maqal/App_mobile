import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_meal_screen.dart';

// ──────────────────────────────────────────────
// COULEURS
// ──────────────────────────────────────────────
const _kPurple  = Color(0xFF6C5CE7);
const _kPurple2 = Color(0xFFA29BFE);
const _kOrange  = Color(0xFFE17055);
const _kGreen   = Color(0xFF00B894);
const _kDark    = Color(0xFF2D2060);
const _kGrey    = Color(0xFF9E8DD0);
const _kBg      = Color(0xFFF8F5FF);
const _kBgCard  = Color(0xFFF0EBFF);

// ──────────────────────────────────────────────
// MODÈLE SLOT REPAS
// ──────────────────────────────────────────────
class _MealSlot {
  final String icon;
  final String name;
  final String mealType;
  final String recommended;
  final Color iconBg;

  const _MealSlot({
    required this.icon, required this.name,
    required this.mealType, required this.recommended,
    required this.iconBg,
  });
}

const _slots = [
  _MealSlot(icon:'🥗', name:'Petit-déjeuner', mealType:'petit-dejeuner',
    recommended:'Recommandé 830–1170 Cal', iconBg:Color(0xFFF0EBFF)),
  _MealSlot(icon:'🍗', name:'Déjeuner', mealType:'dejeuner',
    recommended:'Recommandé 255–370 Cal', iconBg:Color(0xFFFFF0E8)),
  _MealSlot(icon:'🥐', name:'Collation', mealType:'collation',
    recommended:'Recommandé 150–250 Cal', iconBg:Color(0xFFFFFBE8)),
  _MealSlot(icon:'🍽️', name:'Dîner', mealType:'diner',
    recommended:'Recommandé 255–370 Cal', iconBg:Color(0xFFF5F3FF)),
];

// ──────────────────────────────────────────────
// NutritionScreen
// ──────────────────────────────────────────────
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  DateTime _selectedDay = DateTime.now();

  // Repas chargés depuis Firestore pour le jour sélectionné
  // map: mealType → list of entries
  final Map<String, List<Map<String, dynamic>>> _dayMeals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDay(_selectedDay);
  }

  Future<void> _loadDay(DateTime day) async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loading = false); return; }

    try {
      final start = DateTime(day.year, day.month, day.day);
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
        final d = doc.data();
        final type = (d['mealType'] as String?) ?? 'repas';
        grouped.putIfAbsent(type, () => []);
        grouped[type]!.add(d);
      }

      if (mounted) setState(() { _dayMeals
        ..clear()
        ..addAll(grouped); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Génère les 7 jours de la semaine contenant _selectedDay
  List<DateTime> get _weekDays {
    final now = _selectedDay;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  int get _totalCalories {
    int total = 0;
    for (final list in _dayMeals.values) {
      for (final m in list) {
        total += (m['calories'] as num?)?.toInt() ?? 0;
      }
    }
    return total;
  }

  void _selectDay(DateTime d) {
    setState(() => _selectedDay = d);
    _loadDay(d);
  }

  void _goAddMeal() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMealScreen()));
    _loadDay(_selectedDay); // refresh après retour
  }

  String _dayName(int weekday) {
    const names = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = ['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Août','Sep','Oct','Nov','Déc'];
    return names[month - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  @override
  Widget build(BuildContext context) {
    final week = _weekDays;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header purple
          Container(
            color: _kPurple,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Row(
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
                      child: Text('Nutrition 🍏',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    GestureDetector(
                      onTap: _goAddMeal,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Calendrier semaine
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                // Mois + navigation
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _selectDay(_selectedDay.subtract(const Duration(days: 7))),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: _kBgCard, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: const Text('‹', style: TextStyle(fontSize: 16, color: _kPurple, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '📅 ${_isSameDay(_selectedDay, DateTime.now()) ? "Aujourd\'hui, " : ""}${_selectedDay.day} ${_monthName(_selectedDay.month)} ${_selectedDay.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kDark),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _selectDay(_selectedDay.add(const Duration(days: 7))),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: _kBgCard, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: const Text('›', style: TextStyle(fontSize: 16, color: _kPurple, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Jours
                Row(
                  children: week.map((d) {
                    final active = _isSameDay(d, _selectedDay);
                    final today  = _isToday(d);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDay(d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                          decoration: BoxDecoration(
                            color: active ? _kPurple : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(_dayName(d.weekday),
                                style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: active ? Colors.white.withOpacity(0.75) : _kGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${d.day}',
                                style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800,
                                  color: active ? Colors.white : today ? _kPurple : _kDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 2),

          // ── Total calories du jour
          if (_totalCalories > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kPurple2, _kPurple],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('$_totalCalories Cal consommées aujourd\'hui',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),

          // ── Meal slots
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kPurple))
                : RefreshIndicator(
                    color: _kPurple,
                    onRefresh: () => _loadDay(_selectedDay),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                      itemCount: _slots.length,
                      itemBuilder: (_, i) {
                        final slot = _slots[i];
                        final entries = _dayMeals[slot.mealType] ?? [];
                        return _MealSlotCard(
                          slot: slot,
                          entries: entries,
                          onAdd: _goAddMeal,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// MealSlotCard
// ──────────────────────────────────────────────
class _MealSlotCard extends StatelessWidget {
  final _MealSlot slot;
  final List<Map<String, dynamic>> entries;
  final VoidCallback onAdd;

  const _MealSlotCard({
    required this.slot, required this.entries, required this.onAdd,
  });

  int get _totalCal => entries.fold(0, (s, e) => s + ((e['calories'] as num?)?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0EBFF)),
        boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: slot.iconBg, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(slot.icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slot.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kDark)),
                      Text(
                        entries.isEmpty
                            ? slot.recommended
                            : '$_totalCal Cal · ${entries.length} plat${entries.length > 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: entries.isEmpty ? const Color(0xFFB0A8D8) : _kPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                // Add button
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('+ Ajouter',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

          // Entries list (if any)
          if (entries.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF0EBFF)),
            ...entries.map((e) => _EntryRow(entry: e)),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// EntryRow — une ligne de plat ajouté
// ──────────────────────────────────────────────
class _EntryRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final emoji    = (entry['emoji'] as String?)  ?? '🍽️';
    final name     = (entry['name'] as String?)   ?? 'Repas';
    final portions = (entry['portions'] as num?)?.toInt() ?? 1;
    final cal      = (entry['calories'] as num?)?.toInt() ?? 0;
    final gluc     = (entry['glucides'] as num?)?.toInt() ?? 0;
    final prot     = (entry['proteines'] as num?)?.toInt() ?? 0;
    final lip      = (entry['lipides'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$name × $portions',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kDark),
                ),
              ),
              Text('$cal Cal',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kPurple)),
            ],
          ),
          const SizedBox(height: 6),
          // Mini macro bars
          Row(children: [
            _MiniMacro(label: 'G', value: gluc, color: _kPurple),
            const SizedBox(width: 8),
            _MiniMacro(label: 'P', value: prot, color: _kOrange),
            const SizedBox(width: 8),
            _MiniMacro(label: 'L', value: lip, color: _kGreen),
          ]),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text('$label: ${value}g',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}
