import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../widgets/common_widgets.dart';

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});
  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  final _ageCtrl    = TextEditingController();
  final _poidsCtrl  = TextEditingController();
  final _tailleCtrl = TextEditingController();
  String _typeDiabete = 'Type 1';
  bool _loading = false;

  void _save() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    // Diagramme: Remplir infos santé → Base de données → Accès Dashboard
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  void dispose() { _ageCtrl.dispose(); _poidsCtrl.dispose(); _tailleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          WaveHeader(title: 'Infos de santé', onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complétez votre profil de santé',
                      style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: AuthField(label: 'Âge', controller: _ageCtrl,
                        hint: '32', keyboardType: TextInputType.number, prefixIcon: Icons.cake_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: AuthField(label: 'Poids (kg)', controller: _poidsCtrl,
                        hint: '70', keyboardType: TextInputType.number, prefixIcon: Icons.monitor_weight_outlined)),
                  ]),
                  const SizedBox(height: 14),
                  AuthField(label: 'Taille (cm)', controller: _tailleCtrl,
                      hint: '170', keyboardType: TextInputType.number, prefixIcon: Icons.height),
                  const SizedBox(height: 18),
                  const Text('Type de diabète',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(children: ['Type 1', 'Type 2', 'Gestationnel'].map((t) =>
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _typeDiabete = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 42,
                          decoration: BoxDecoration(
                            color: _typeDiabete == t ? AppColors.c6 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _typeDiabete == t ? AppColors.c6 : AppColors.c3, width: 1.5),
                          ),
                          child: Center(child: Text(t,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                  color: _typeDiabete == t ? Colors.white : AppColors.textDark))),
                        ),
                      ),
                    ))).toList(),
                  ),
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
