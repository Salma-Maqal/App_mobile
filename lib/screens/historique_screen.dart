import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────
// Constantes couleurs
// ─────────────────────────────────────────
const _kPurple  = Color(0xFF6C5CE7);
const _kOrange  = Color(0xFFE17055);
const _kGreen   = Color(0xFF00B894);
const _kBlue    = Color(0xFF0984E3);
const _kDark    = Color(0xFF2D2060);
const _kGrey    = Color(0xFF9E8DD0);
const _kBg      = Color(0xFFF8F5FF);

// ─────────────────────────────────────────
// Filtres
// ─────────────────────────────────────────
const _filters = [
  _Filter('Tout',     null,        Icons.apps_rounded),
  _Filter('Repas',    'meal',      Icons.restaurant_rounded),
  _Filter('Sport',    'sport',     Icons.fitness_center_rounded),
  _Filter('Glycémie', 'glycemie',  Icons.water_drop_rounded),
  _Filter('Eau',      'water',     Icons.local_drink_rounded),
];

class _Filter {
  final String label;
  final String? type;
  final IconData icon;
  const _Filter(this.label, this.type, this.icon);
}

// ─────────────────────────────────────────
// Entry model
// ─────────────────────────────────────────
class _HistEntry {
  final String type, icon, name, sub, value;
  final Color valueColor;
  final DateTime dt;

  const _HistEntry({
    required this.type, required this.icon, required this.name,
    required this.sub,  required this.value, required this.valueColor,
    required this.dt,
  });
}

// ─────────────────────────────────────────
// HistoriqueScreen
// ─────────────────────────────────────────
class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});
  @override State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen>
    with WidgetsBindingObserver {
  int _filterIndex = 0;
  bool _loading = true;
  String? _error;
  List<_HistEntry> _allEntries = [];

  // Track last load time to auto-refresh when widget becomes active
  DateTime? _lastLoad;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maybeRefresh();
  }

  // Called every time this widget is rebuilt (incl. when tab switched to it)
  @override
  void didUpdateWidget(covariant HistoriqueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeRefresh();
  }

  void _maybeRefresh() {
    final now = DateTime.now();
    if (_lastLoad == null || now.difference(_lastLoad!).inSeconds > 5) {
      _load();
    }
  }

  // ── Helpers date ──
  String _dayLabel(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(dt.year, dt.month, dt.day);
    final diff  = today.difference(d).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    if (diff < 7)  return 'Il y a $diff jours';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ── Chargement sans orderBy (évite l'index composite Firestore) ──
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _lastLoad = DateTime.now(); });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final uid = user.uid;
    final List<_HistEntry> entries = [];

    // helper pour fetch sans orderBy
    Future<List<QueryDocumentSnapshot>> _fetch(String col) async {
      final snap = await FirebaseFirestore.instance
          .collection(col)
          .where('userId', isEqualTo: uid)
          .limit(40)
          .get();
      return snap.docs;
    }

    try {
      // ── Repas
      final meals = await _fetch('meals');
      for (final doc in meals) {
        final d  = doc.data() as Map<String, dynamic>;
        final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final emoji = (d['emoji'] as String?) ?? '🥘';
        entries.add(_HistEntry(
          type: 'meal',
          icon: emoji,
          name: (d['name'] as String?) ?? 'Repas',
          sub:  (d['mealType'] as String?) ?? 'repas',
          value: '${(d['calories'] as num?)?.toInt() ?? 0} Cal',
          valueColor: _kOrange,
          dt: ts,
        ));
      }

      // ── Sport
      final sport = await _fetch('sport_entries');
      for (final doc in sport) {
        final d  = doc.data() as Map<String, dynamic>;
        final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        entries.add(_HistEntry(
          type: 'sport',
          icon: '🏃',
          name: (d['activity'] as String?) ?? 'Activité',
          sub:  '${(d['duration'] as num?)?.toInt() ?? 0} min',
          value: '−${(d['calories'] as num?)?.toInt() ?? 0} Cal',
          valueColor: _kGreen,
          dt: ts,
        ));
      }

      // ── Glycémie
      final glyc = await _fetch('glycemie_entries');
      for (final doc in glyc) {
        final d  = doc.data() as Map<String, dynamic>;
        final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        entries.add(_HistEntry(
          type: 'glycemie',
          icon: '🩸',
          name: 'Glycémie',
          sub:  (d['moment'] as String?) ?? '',
          value: '${(d['value'] as num?)?.toInt() ?? 0} mg/dL',
          valueColor: _kPurple,
          dt: ts,
        ));
      }

      // ── Eau
      final water = await _fetch('water_entries');
      for (final doc in water) {
        final d  = doc.data() as Map<String, dynamic>;
        final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        entries.add(_HistEntry(
          type: 'water',
          icon: '💧',
          name: 'Eau',
          sub:  'Hydratation',
          value: '+${(d['ml'] as num?)?.toInt() ?? 0} mL',
          valueColor: _kBlue,
          dt: ts,
        ));
      }

      // ── Tri par date desc (dans Dart, pas Firestore)
      entries.sort((a, b) => b.dt.compareTo(a.dt));

      if (mounted) setState(() { _allEntries = entries; _loading = false; });

    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Filtrer par type ──
  List<_HistEntry> get _filtered {
    final type = _filters[_filterIndex].type;
    if (type == null) return _allEntries;
    return _allEntries.where((e) => e.type == type).toList();
  }

  // ── Grouper par jour ──
  Map<String, List<_HistEntry>> get _grouped {
    final Map<String, List<_HistEntry>> m = {};
    for (final e in _filtered) {
      final label = _dayLabel(e.dt);
      m.putIfAbsent(label, () => []);
      m[label]!.add(e);
    }
    return m;
  }

  // ── Résumé calories d'un groupe ──
  int _dayCal(List<_HistEntry> entries)  =>
      entries.where((e) => e.type == 'meal')
        .fold(0, (s, e) => s + (int.tryParse(e.value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0));
  int _dayBurn(List<_HistEntry> entries) =>
      entries.where((e) => e.type == 'sport')
        .fold(0, (s, e) => s + (int.tryParse(e.value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0));

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final keys    = grouped.keys.toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header
          Container(
            color: _kBg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Navigator.canPop(context)
                              ? const Color(0xFFF0EBFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Navigator.canPop(context)
                            ? const Icon(Icons.chevron_left, color: _kPurple, size: 20)
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const Expanded(
                      child: Text('Historique',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kDark)),
                    ),
                    // Refresh button
                    GestureDetector(
                      onTap: _load,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EBFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.refresh_rounded, color: _kPurple, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filtres
          SizedBox(
            height: 44,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final f      = _filters[i];
                final active = _filterIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? _kPurple : Colors.white,
                      border: Border.all(color: active ? _kPurple : const Color(0xFFE8E0FF)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(f.icon, size: 13, color: active ? Colors.white : _kGrey),
                        const SizedBox(width: 5),
                        Text(f.label,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: active ? Colors.white : _kGrey,
                          )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // ── Contenu
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kPurple))
                : _error != null
                    ? _ErrorWidget(error: _error!, onRetry: _load)
                    : _filtered.isEmpty
                        ? _EmptyWidget(filterIndex: _filterIndex)
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: _kPurple,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: keys.length,
                              itemBuilder: (_, dayIdx) {
                                final key     = keys[dayIdx];
                                final entries = grouped[key]!;
                                final cal     = _dayCal(entries);
                                final burn    = _dayBurn(entries);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Day header
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(key,
                                            style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w800, color: _kDark)),
                                          Row(children: [
                                            if (cal > 0) ...[
                                              const Text('🔥', style: TextStyle(fontSize: 11)),
                                              const SizedBox(width: 2),
                                              Text('$cal Cal',
                                                style: const TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.w700, color: _kOrange)),
                                            ],
                                            if (burn > 0) ...[
                                              const SizedBox(width: 8),
                                              const Text('🏃', style: TextStyle(fontSize: 11)),
                                              const SizedBox(width: 2),
                                              Text('−$burn Cal',
                                                style: const TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen)),
                                            ],
                                          ]),
                                        ],
                                      ),
                                    ),
                                    // ── Entries
                                    ...entries.map((e) => _EntryCard(entry: e)),
                                  ],
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

// ─────────────────────────────────────────
// Entry card
// ─────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final _HistEntry entry;
  const _EntryCard({required this.entry});

  Color get _iconBg {
    switch (entry.type) {
      case 'meal':     return const Color(0xFFEEE8FF);
      case 'sport':    return const Color(0xFFFFF0E8);
      case 'glycemie': return const Color(0xFFFFE8E8);
      case 'water':    return const Color(0xFFE8F4FF);
      default:         return const Color(0xFFF5F3FF);
    }
  }

  String _timeStr(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EBFF)),
        boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(entry.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDark)),
                Row(children: [
                  if (entry.sub.isNotEmpty)
                    Text(entry.sub,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB0A8D8))),
                  if (entry.sub.isNotEmpty) const Text(' · ', style: TextStyle(fontSize: 11, color: Color(0xFFD0C8F0))),
                  Text(_timeStr(entry.dt),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB0A8D8))),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: entry.valueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(entry.value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: entry.valueColor)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────
class _EmptyWidget extends StatelessWidget {
  final int filterIndex;
  const _EmptyWidget({required this.filterIndex});

  @override
  Widget build(BuildContext context) {
    final labels = ['entrée', 'repas', 'activité', 'mesure de glycémie', 'eau'];
    final icons  = ['📋', '🍽️', '🏃', '🩸', '💧'];
    final idx = filterIndex.clamp(0, 4);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icons[idx], style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            'Aucun${idx == 2 ? "ne" : ""} ${labels[idx]}\nenregistré${idx == 2 ? "e" : ""}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFB0A8D8)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Error widget
// ─────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Erreur de chargement',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kDark)),
            const SizedBox(height: 8),
            Text(error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: _kGrey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
