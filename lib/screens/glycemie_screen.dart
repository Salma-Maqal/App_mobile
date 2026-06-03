import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  ENTRY POINT (pour tester en standalone)
// ─────────────────────────────────────────────
void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4834D4)),
        fontFamily: 'Roboto',
      ),
      home: const GlycemieScreen(),
    );
  }
}

// ─────────────────────────────────────────────
//  CONSTANTES COULEURS
// ─────────────────────────────────────────────
class _C {
  static const purple     = Color(0xFF6C5CE7);
  static const purpleDark = Color(0xFF4834D4);
  static const purpleLight= Color(0xFFA29BFE);
  static const bg         = Color(0xFFF8F7FF);
  static const cardBg     = Colors.white;
  static const textDark   = Color(0xFF2D3436);
  static const muted      = Color(0xFF636E72);
  static const low        = Color(0xFF0984E3);
  static const normal     = Color(0xFF00B894);
  static const high       = Color(0xFFE17055);
  static const danger     = Color(0xFFD63031);
  static const border     = Color(0x266C5CE7);
}

// ─────────────────────────────────────────────
//  MODÈLES
// ─────────────────────────────────────────────
enum GlycemieStatus { low, normal, high, danger }

extension GlycemieStatusExt on GlycemieStatus {
  String get label {
    switch (this) {
      case GlycemieStatus.low:    return 'Hypoglycémie';
      case GlycemieStatus.normal: return 'Normale';
      case GlycemieStatus.high:   return 'Élevée';
      case GlycemieStatus.danger: return 'Hyperglycémie';
    }
  }
  Color get color {
    switch (this) {
      case GlycemieStatus.low:    return _C.low;
      case GlycemieStatus.normal: return _C.normal;
      case GlycemieStatus.high:   return _C.high;
      case GlycemieStatus.danger: return _C.danger;
    }
  }
  Color get bgColor {
    switch (this) {
      case GlycemieStatus.low:    return const Color(0xFFE3F2FD);
      case GlycemieStatus.normal: return const Color(0xFFE8FAF4);
      case GlycemieStatus.high:   return const Color(0xFFFFF3F0);
      case GlycemieStatus.danger: return const Color(0xFFFFF0F0);
    }
  }
  IconData get icon {
    switch (this) {
      case GlycemieStatus.low:    return Icons.arrow_downward_rounded;
      case GlycemieStatus.normal: return Icons.check_circle_outline_rounded;
      case GlycemieStatus.high:   return Icons.arrow_upward_rounded;
      case GlycemieStatus.danger: return Icons.warning_amber_rounded;
    }
  }
}

GlycemieStatus _classifyValue(double v) {
  if (v < 70)  return GlycemieStatus.low;
  if (v <= 180) return GlycemieStatus.normal;
  if (v <= 250) return GlycemieStatus.high;
  return GlycemieStatus.danger;
}

class GlycemieEntry {
  final double value;
  final String moment;
  final String timeLabel;
  GlycemieEntry(this.value, this.moment, this.timeLabel);
  GlycemieStatus get status => _classifyValue(value);
}

// ─────────────────────────────────────────────
//  ÉCRAN PRINCIPAL
// ─────────────────────────────────────────────
class GlycemieScreen extends StatefulWidget {
  const GlycemieScreen({super.key});
  @override
  State<GlycemieScreen> createState() => _GlycemieScreenState();
}

class _GlycemieScreenState extends State<GlycemieScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMoment = 1; // "Avant repas" par défaut
  final TextEditingController _valueCtrl =
      TextEditingController(text: '118');

  bool _saved = false;
  bool _showAlert = false;
  bool _showNotifPanel = false;
  String _alertTitle = 'Hyperglycémie détectée';
  String _alertMessage = '210 mg/dL — À jeun. Consultez votre médecin.';

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Hyperglycémie détectée',
      'body': '210 mg/dL — À jeun · Hier 07:00',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFD63031),
      'read': false,
    },
    {
      'title': 'Rappel de mesure',
      'body': 'N\'oubliez pas de mesurer avant le déjeuner',
      'icon': Icons.notifications_active_rounded,
      'color': Color(0xFF6C5CE7),
      'read': false,
    },
    {
      'title': 'Glycémie élevée',
      'body': '198 mg/dL — Après repas · Hier 13:15',
      'icon': Icons.arrow_upward_rounded,
      'color': Color(0xFFE17055),
      'read': true,
    },
  ];

  final List<String> _moments = [
    'À jeun',
    'Avant repas',
    'Après repas',
    'Coucher',
  ];

  final List<GlycemieEntry> _history = [
    GlycemieEntry(118, 'Avant repas',   "Aujourd'hui, 08:30"),
    GlycemieEntry(198, 'Après repas',   'Hier, 13:15'),
    GlycemieEntry(210, 'À jeun',        'Hier, 07:00'),
    GlycemieEntry(95,  'Avant repas',   'Dim, 12:00'),
    GlycemieEntry(62,  'Coucher',       'Sam, 22:45'),
    GlycemieEntry(108, 'À jeun',        'Sam, 07:30'),
  ];

  // Données courbe 7 jours (mg/dL)
  final List<double> _weekData = [140, 118, 198, 210, 115, 135, 108, 125];
  final List<String> _weekLabels = ['L','M','M','J','V','S','D','A'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final val = double.tryParse(_valueCtrl.text) ?? 0;
    if (val <= 0) return;
    final status = _classifyValue(val);
    final now = DateTime.now();
    final timeLabel =
        "Aujourd'hui, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final newEntry = GlycemieEntry(val, _moments[_selectedMoment], timeLabel);

    setState(() {
      _saved = true;
      _history.insert(0, newEntry);
      // Update chart: keep last 8 points
      _weekData.add(val);
      if (_weekData.length > 8) _weekData.removeAt(0);
      _weekLabels.add(_dayLabel(now.weekday));
      if (_weekLabels.length > 8) _weekLabels.removeAt(0);
      _showAlert = status == GlycemieStatus.danger || status == GlycemieStatus.high;
      _alertMessage = '${val.toInt()} mg/dL — ${_moments[_selectedMoment]}. Consultez votre médecin.';
      _alertTitle = status == GlycemieStatus.danger
          ? 'Hyperglycémie détectée'
          : 'Glycémie élevée';
      if (_showAlert) {
        _notifications.insert(0, {
          'title': _alertTitle,
          'body': '${val.toInt()} mg/dL — ${_moments[_selectedMoment]} · $timeLabel',
          'icon': status == GlycemieStatus.danger
              ? Icons.warning_amber_rounded
              : Icons.arrow_upward_rounded,
          'color': status.color,
          'read': false,
        });
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  String _dayLabel(int weekday) {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return labels[(weekday - 1) % 7];
  }

  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSaisieTab(),
                    _buildCourbeTab(),
                    _buildHistoriqueTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_showNotifPanel) _buildNotifPanel(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // NOTIFICATION PANEL
  // ──────────────────────────────────────────
  Widget _buildNotifPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 100),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark,
                          ),
                        ),
                        Row(
                          children: [
                            if (_notifications.any((n) => n['read'] == false))
                              GestureDetector(
                                onTap: () => setState(() {
                                  for (var n in _notifications) n['read'] = true;
                                }),
                                child: const Text(
                                  'Tout lire',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _C.purple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setState(() => _showNotifPanel = false),
                              child: const Icon(Icons.close_rounded,
                                  size: 20, color: _C.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_notifications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 36, color: _C.muted),
                            SizedBox(height: 8),
                            Text('Aucune notification',
                                style: TextStyle(color: _C.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 16, endIndent: 16, color: _C.border),
                      itemBuilder: (_, i) => _buildNotifItem(i),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifItem(int index) {
    final notif = _notifications[index];
    final color = notif['color'] as Color;
    final isUnread = notif['read'] == false;
    return GestureDetector(
      onTap: () => setState(() => _notifications[index]['read'] = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isUnread ? _C.purple.withOpacity(0.04) : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(notif['icon'] as IconData, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: _C.textDark,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: _C.purple,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif['body'] as String,
                    style: const TextStyle(fontSize: 11, color: _C.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.purpleDark, _C.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bloodtype_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Glycémie',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showNotifPanel = !_showNotifPanel),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            _showNotifPanel
                                ? Icons.notifications_rounded
                                : Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          if (_notifications.any((n) => n['read'] == false))
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B6B),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${_notifications.where((n) => n['read'] == false).length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: _C.purpleDark,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Saisie'),
                    Tab(text: 'Courbe'),
                    Tab(text: 'Historique'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // ONGLET 0 : SAISIE
  // ──────────────────────────────────────────
  Widget _buildSaisieTab() {
    final lastEntry = _history.first;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Alerte toast
        if (_showAlert) _buildAlertToast(),

        // Dernière mesure
        _buildLastValueCard(lastEntry),
        const SizedBox(height: 12),

        // Mini stats (calculées dynamiquement depuis _history)
        _buildMiniStats(),
        const SizedBox(height: 12),

        // Saisie
        _buildInputCard(),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildAlertToast() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3436),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFFAA00), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_alertTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(_alertMessage,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showAlert = false),
            child: const Icon(Icons.close_rounded,
                color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLastValueCard(GlycemieEntry entry) {
    final status = entry.status;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barre colorée latérale
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: status.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DERNIÈRE MESURE',
                      style: TextStyle(
                          fontSize: 10,
                          color: _C.muted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          entry.value.toInt().toString(),
                          style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: _C.textDark,
                              height: 1),
                        ),
                        const SizedBox(width: 4),
                        const Text('mg/dL',
                            style: TextStyle(
                                fontSize: 14, color: _C.muted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon,
                              size: 12, color: status.color),
                          const SizedBox(width: 4),
                          Text(status.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: status.color)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: _C.muted),
                        const SizedBox(width: 4),
                        Text(
                          "${entry.timeLabel} · ${entry.moment}",
                          style: const TextStyle(
                              fontSize: 11, color: _C.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStats() {
    final vals = _history.map((e) => e.value).toList();
    final min = vals.reduce((a, b) => a < b ? a : b);
    final max = vals.reduce((a, b) => a > b ? a : b);
    final avg = vals.reduce((a, b) => a + b) / vals.length;

    return Row(
      children: [
        _miniStatCard('${min.toInt()}', 'Min (7j)',
            icon: Icons.arrow_downward_rounded, color: _C.low),
        const SizedBox(width: 8),
        _miniStatCard('${avg.toInt()}', 'Moy (7j)',
            icon: Icons.horizontal_rule_rounded, color: _C.purple),
        const SizedBox(width: 8),
        _miniStatCard('${max.toInt()}', 'Max (7j)',
            icon: Icons.arrow_upward_rounded, color: _C.high),
      ],
    );
  }

  Widget _miniStatCard(String value, String label,
      {required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: _C.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: const [
              Icon(Icons.edit_note_rounded,
                  size: 18, color: _C.purple),
              SizedBox(width: 8),
              Text('Nouvelle mesure',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark)),
            ],
          ),
          const SizedBox(height: 14),

          // Moment de mesure
          const Text(
            'Moment de mesure',
            style: TextStyle(
                fontSize: 11,
                color: _C.muted,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_moments.length, (i) {
              final selected = i == _selectedMoment;
              return GestureDetector(
                onTap: () => setState(() => _selectedMoment = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? _C.purple : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _C.purple : _C.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _moments[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _C.muted,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Champ valeur
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bloodtype_rounded,
                    color: _C.purple, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valeur glycémie',
                      style: TextStyle(
                          fontSize: 11,
                          color: _C.muted,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _valueCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F7FF),
                        suffixText: 'mg/dL',
                        suffixStyle: const TextStyle(
                            fontSize: 12,
                            color: _C.muted,
                            fontWeight: FontWeight.w500),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _C.border, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _C.border, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: _C.purple, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bouton enregistrer
          SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _saved
                      ? [const Color(0xFF00B894), const Color(0xFF00CEC9)]
                      : [_C.purpleDark, _C.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(
                  _saved ? Icons.check_rounded : Icons.save_rounded,
                  size: 18,
                ),
                label: Text(
                  _saved ? 'Enregistré avec succès !' : 'Enregistrer la mesure',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // ONGLET 1 : COURBE
  // ──────────────────────────────────────────
  Widget _buildCourbeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Courbe
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Évolution sur 7 jours',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark)),
                  Row(
                    children: const [
                      Text('7 jours',
                          style: TextStyle(
                              fontSize: 11,
                              color: _C.purple,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: _C.purple),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Légende
              Row(
                children: [
                  _legendItem(
                      color: const Color(0xFF00B894),
                      bg: const Color(0xFFE8F5E9),
                      label: 'Zone normale'),
                  const SizedBox(width: 14),
                  _legendItem(color: _C.purple, label: 'Vos mesures'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: CustomPaint(
                  size: const Size(double.infinity, 110),
                  painter: _GlycemiChartPainter(
                    values: _weekData,
                    labels: _weekLabels,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Répartition calculée depuis l'historique réel
        Builder(builder: (context) {
          final total = _history.length;
          final low = _history.where((e) => e.status == GlycemieStatus.low).length;
          final normal = _history.where((e) => e.status == GlycemieStatus.normal).length;
          final high = _history.where((e) => e.status == GlycemieStatus.high || e.status == GlycemieStatus.danger).length;
          String pct(int n) => total == 0 ? '0%' : '${(n * 100 ~/ total)}%';
          double ratio(int n) => total == 0 ? 0 : n / total;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Répartition des mesures',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark)),
                const SizedBox(height: 12),
                _repartitionRow(_C.low, 'Hypoglycémie (<70)', ratio(low), pct(low)),
                const SizedBox(height: 8),
                _repartitionRow(_C.normal, 'Normale (70–180)', ratio(normal), pct(normal)),
                const SizedBox(height: 8),
                _repartitionRow(_C.high, 'Hyperglycémie (>180)', ratio(high), pct(high)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _legendItem({required Color color, Color? bg, required String label}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: bg ?? color,
            shape: BoxShape.circle,
            border: bg != null
                ? Border.all(color: color, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: _C.muted)),
      ],
    );
  }

  Widget _repartitionRow(
      Color color, String label, double ratio, String pct) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 12, color: _C.muted)),
        ),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: const Color(0xFFF0F0F0),
              color: color,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(pct,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark)),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // ONGLET 2 : HISTORIQUE
  // ──────────────────────────────────────────
  Widget _buildHistoriqueTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildHistoryItem(_history[i]),
    );
  }

  Widget _buildHistoryItem(GlycemieEntry entry) {
    final status = entry.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          // Dot coloré
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Valeur + moment
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${entry.value.toInt()} ',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark),
                      ),
                      const TextSpan(
                        text: 'mg/dL',
                        style: TextStyle(
                            fontSize: 11,
                            color: _C.muted,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(entry.moment,
                    style: const TextStyle(
                        fontSize: 11, color: _C.muted)),
              ],
            ),
          ),
          // Heure + badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(entry.timeLabel,
                  style: const TextStyle(
                      fontSize: 11, color: _C.muted)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status.bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == GlycemieStatus.danger ||
                        status == GlycemieStatus.low)
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Icon(Icons.warning_amber_rounded,
                            size: 10, color: status.color),
                      ),
                    Text(status.label,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: status.color)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // BOTTOM NAV
  // ──────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.home_rounded,           'label': 'Accueil'},
      {'icon': Icons.restaurant_menu_rounded,'label': 'Nutrition'},
      {'icon': Icons.bloodtype_rounded,      'label': 'Glycémie'},
      {'icon': Icons.water_drop_rounded,     'label': 'Eau'},
      {'icon': Icons.directions_run_rounded, 'label': 'Sport'},
    ];
    const activeIdx = 2;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == activeIdx;
              final iconData = items[i]['icon'] as IconData;
              final label = items[i]['label'] as String;
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconData,
                        size: 22,
                        color: active ? _C.purple : const Color(0xFFB2BEC3)),
                    const SizedBox(height: 3),
                    Text(label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active
                              ? _C.purple
                              : const Color(0xFFB2BEC3),
                        )),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CUSTOM PAINTER — Courbe glycémie
// ─────────────────────────────────────────────
class _GlycemiChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _GlycemiChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    const double minY = 0, maxY = 280;
    const double normalLow = 70, normalHigh = 180;
    const double labelH = 18;
    final chartH = size.height - labelH;
    final n = values.length;
    final stepX = size.width / (n - 1);

    double toY(double v) =>
        chartH - ((v - minY) / (maxY - minY)) * chartH;

    // Zone normale (fond vert)
    final zonePaint = Paint()
      ..color = const Color(0xFFE8FAF4);
    final zoneTop    = toY(normalHigh);
    final zoneBottom = toY(normalLow);
    canvas.drawRect(
        Rect.fromLTWH(0, zoneTop, size.width, zoneBottom - zoneTop),
        zonePaint);

    // Courbe
    final linePaint = Paint()
      ..color = _C.purple
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < n; i++) {
      final x = i * stepX;
      final y = toY(values[i]);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }

    // Gradient fill under curve
    final fillPath = Path()..addPath(path, Offset.zero);
    fillPath.lineTo((n - 1) * stepX, chartH);
    fillPath.lineTo(0, chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _C.purple.withOpacity(0.25),
          _C.purple.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Points
    for (int i = 0; i < n; i++) {
      final x = i * stepX;
      final y = toY(values[i]);
      final status = _classifyValue(values[i]);
      final isAlert = status == GlycemieStatus.high || status == GlycemieStatus.danger;

      // Halo blanc
      canvas.drawCircle(Offset(x, y), isAlert ? 6 : 5,
          Paint()..color = Colors.white);
      canvas.drawCircle(
          Offset(x, y),
          isAlert ? 5 : 4,
          Paint()..color = isAlert ? status.color : _C.purple);
    }

    // Labels X
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      tp.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 8, color: Color(0xFFB2BEC3)),
      );
      tp.layout();
      tp.paint(canvas,
          Offset(i * stepX - tp.width / 2, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
