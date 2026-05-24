import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CompanionInfoScreen extends StatefulWidget {
  const CompanionInfoScreen({super.key});
  @override
  State<CompanionInfoScreen> createState() => _CompanionInfoScreenState();
}

class _CompanionInfoScreenState extends State<CompanionInfoScreen> {
  final _relationCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  bool _loading = false;

  void _save() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    // Diagramme: Remplir infos accompagnant → Base de données → Accès Dashboard
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  void dispose() { _relationCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          WaveHeader(title: 'Profil accompagnant', onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informations en tant qu\'accompagnant',
                      style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
                  const SizedBox(height: 20),
                  AuthField(label: 'Relation avec le patient', controller: _relationCtrl,
                      hint: 'Parent, conjoint, ami...', prefixIcon: Icons.favorite_outline),
                  const SizedBox(height: 14),
                  AuthField(label: 'Téléphone', controller: _phoneCtrl,
                      hint: '+212 6XX XXX XXX', keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined),
                  const SizedBox(height: 32),
                  PrimaryButton(label: 'Enregistrer et continuer', onPressed: _save, loading: _loading),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
