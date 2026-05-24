import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class AddCompanionScreen extends StatefulWidget {
  const AddCompanionScreen({super.key});
  @override
  State<AddCompanionScreen> createState() => _AddCompanionScreenState();
}

class _AddCompanionScreenState extends State<AddCompanionScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  // Diagramme: Existe? / Invitation acceptée?
  _Step _step = _Step.saisir;

  void _verify() async {
    if (_emailCtrl.text.isEmpty) {
      setState(() => _error = 'Veuillez entrer un email.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);

    // Diagramme: Vérifier existence dans BD
    // Simulation: email valide si contient '@'
    if (!_emailCtrl.text.contains('@')) {
      // Diagramme: Existe? → Non → Afficher erreur
      setState(() => _error = 'Cet utilisateur n\'existe pas dans la base de données.');
      return;
    }

    // Diagramme: Existe? → Oui → Créer invitation → Envoyer Email → Attente acceptation
    setState(() => _step = _Step.attente);
    _sendInvitation();
  }

  void _sendInvitation() async {
    // Diagramme: Créer invitation → Envoyer Email
    await Future.delayed(const Duration(milliseconds: 800));
    // Reste en attente — l'accompagnant doit accepter
  }

  void _simulateAccepted() async {
    // Diagramme: Invitation acceptée? → Oui → Créer relation
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() { _loading = false; _step = _Step.relation; });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    // Diagramme: Créer relation → retour Dashboard (join state)
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _simulateRefused() {
    // Diagramme: Invitation acceptée? → Non → retour attente
    setState(() { _step = _Step.saisir; _emailCtrl.clear(); _error = 'Invitation refusée. Essayez un autre accompagnant.'; });
  }

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          WaveHeader(title: 'Ajouter accompagnant', onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {

      // ── ÉTAPE 1: Saisir email accompagnant ──────────────────
      case _Step.saisir:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Entrez l\'email de votre accompagnant pour l\'inviter.',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.5)),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.4)),
              ),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          AuthField(label: 'Email de l\'accompagnant', controller: _emailCtrl,
              hint: 'accompagnant@gmail.com', keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Vérifier et inviter', onPressed: _verify, loading: _loading),
        ]);

      // ── ÉTAPE 2: Attente acceptation ────────────────────────
      case _Step.attente:
        return Column(children: [
          const SizedBox(height: 20),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.c2, shape: BoxShape.circle),
            child: Icon(Icons.mark_email_read_outlined, color: AppColors.c6, size: 38),
          ),
          const SizedBox(height: 20),
          const Text('Invitation envoyée !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 10),
          Text('Un email a été envoyé à\n${_emailCtrl.text}\nEn attente d\'acceptation...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.6)),
          const SizedBox(height: 30),
          // Simulation boutons pour tester le flow du diagramme
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.c3),
            ),
            child: Column(children: [
              Text('Simuler la réponse de l\'accompagnant',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton(
                  onPressed: _loading ? null : _simulateAccepted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.c6, foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Accepter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(
                  onPressed: _simulateRefused,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Refuser', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                )),
              ]),
            ]),
          ),
        ]);

      // ── ÉTAPE 3: Créer relation (succès) ────────────────────
      case _Step.relation:
        return Column(children: [
          const SizedBox(height: 30),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.c2, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline, color: AppColors.c6, size: 42),
          ),
          const SizedBox(height: 20),
          const Text('Relation créée !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 10),
          Text('Votre accompagnant a accepté l\'invitation.\nRedirection vers le tableau de bord...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.6)),
          const SizedBox(height: 20),
          CircularProgressIndicator(color: AppColors.c6, strokeWidth: 2.5),
        ]);
    }
  }
}

enum _Step { saisir, attente, relation }
