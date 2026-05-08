import 'package:flutter/material.dart';
import '../app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _rappelRepas      = true;
  bool _rappelGlycemie   = true;
  bool _alerteSucre      = true;
  bool _conseilsNutrition = false;
  bool _rapportHebdo     = true;
  bool _rappelEau        = false;

  TimeOfDay _heureRepas    = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _heureGlycemie = const TimeOfDay(hour: 8,  minute: 0);

  Future<void> _pickTime(TimeOfDay current, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Banner info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(
                'Activez les rappels pour mieux gérer votre diabète au quotidien.',
                style: TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
              )),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Rappels repas
          _sectionLabel('RAPPELS REPAS'),
          const SizedBox(height: 10),
          _SwitchTile(
            icon: Icons.restaurant_rounded,
            iconColor: Colors.green,
            title: 'Rappel repas',
            subtitle: 'Notification avant chaque repas',
            value: _rappelRepas,
            onChanged: (v) => setState(() => _rappelRepas = v),
          ),
          if (_rappelRepas) _TimeTile(
            label: 'Heure du rappel déjeuner',
            time: _heureRepas,
            onTap: () => _pickTime(_heureRepas,
                (t) => setState(() => _heureRepas = t)),
          ),
          const SizedBox(height: 4),
          _SwitchTile(
            icon: Icons.water_drop_rounded,
            iconColor: Colors.blue,
            title: 'Rappel eau',
            subtitle: 'Rappel hydratation toutes les 2h',
            value: _rappelEau,
            onChanged: (v) => setState(() => _rappelEau = v),
          ),

          const SizedBox(height: 20),

          // ── Glycémie
          _sectionLabel('GLYCÉMIE'),
          const SizedBox(height: 10),
          _SwitchTile(
            icon: Icons.monitor_heart_rounded,
            iconColor: Colors.red,
            title: 'Rappel mesure glycémie',
            subtitle: 'Rappel quotidien pour mesurer',
            value: _rappelGlycemie,
            onChanged: (v) => setState(() => _rappelGlycemie = v),
          ),
          if (_rappelGlycemie) _TimeTile(
            label: 'Heure de mesure',
            time: _heureGlycemie,
            onTap: () => _pickTime(_heureGlycemie,
                (t) => setState(() => _heureGlycemie = t)),
          ),
          const SizedBox(height: 4),
          _SwitchTile(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            title: 'Alerte sucre élevé',
            subtitle: 'Notification si > 50g sucre/jour',
            value: _alerteSucre,
            onChanged: (v) => setState(() => _alerteSucre = v),
          ),

          const SizedBox(height: 20),

          // ── Conseils
          _sectionLabel('CONSEILS & RAPPORTS'),
          const SizedBox(height: 10),
          _SwitchTile(
            icon: Icons.tips_and_updates_rounded,
            iconColor: Colors.purple,
            title: 'Conseils nutrition',
            subtitle: 'Astuces quotidiennes pour diabétiques',
            value: _conseilsNutrition,
            onChanged: (v) => setState(() => _conseilsNutrition = v),
          ),
          const SizedBox(height: 4),
          _SwitchTile(
            icon: Icons.bar_chart_rounded,
            iconColor: Colors.teal,
            title: 'Rapport hebdomadaire',
            subtitle: 'Résumé chaque dimanche matin',
            value: _rapportHebdo,
            onChanged: (v) => setState(() => _rapportHebdo = v),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('✅ Préférences enregistrées !'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              child: const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: AppColors.primary, letterSpacing: 1.2)),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.icon, required this.iconColor,
      required this.title, required this.subtitle,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: ListTile(
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: Switch.adaptive(
        value: value, onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.primary))),
        Text(time.format(context),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(width: 6),
        Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
      ]),
    ),
  );
}