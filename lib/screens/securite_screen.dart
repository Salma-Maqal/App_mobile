import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';

class SecuriteScreen extends StatefulWidget {
  const SecuriteScreen({super.key});
  @override
  State<SecuriteScreen> createState() => _SecuriteScreenState();
}

class _SecuriteScreenState extends State<SecuriteScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _oldPwdCtrl   = TextEditingController();
  final _newPwdCtrl   = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _showOld     = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _saving      = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      // Re-authenticate first
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _oldPwdCtrl.text);
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(_newPwdCtrl.text);

      if (mounted) {
        _snack('✅ Mot de passe modifié avec succès !');
        _oldPwdCtrl.clear();
        _newPwdCtrl.clear();
        _confirmCtrl.clear();
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Erreur inconnue';
      if (e.code == 'wrong-password') msg = 'Mot de passe actuel incorrect.';
      if (e.code == 'weak-password')  msg = 'Mot de passe trop faible (min 6 caractères).';
      _snack(msg, error: true);
    } catch (_) {
      _snack('Erreur lors du changement', error: true);
    }
    setState(() => _saving = false);
  }

  Future<void> _sendResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      _snack('📧 Email de réinitialisation envoyé à ${user.email}');
    } catch (_) {
      _snack('Erreur lors de l\'envoi', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? Colors.red : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _oldPwdCtrl.dispose(); _newPwdCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Sécurité', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Info compte
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.85), AppColors.primary]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              const CircleAvatar(
                radius: 24, backgroundColor: Colors.white24,
                child: Icon(Icons.shield_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Compte sécurisé',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(email, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Email', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ]),
          ),

          const SizedBox(height: 28),

          // ── Changer mot de passe
          _sectionLabel('CHANGER LE MOT DE PASSE'),
          const SizedBox(height: 12),

          Form(
            key: _formKey,
            child: Column(children: [

              // Mot de passe actuel
              _PwdField(
                ctrl: _oldPwdCtrl, label: 'Mot de passe actuel',
                show: _showOld, onToggle: () => setState(() => _showOld = !_showOld),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),

              // Nouveau mot de passe
              _PwdField(
                ctrl: _newPwdCtrl, label: 'Nouveau mot de passe',
                show: _showNew, onToggle: () => setState(() => _showNew = !_showNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (v.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),

              // Confirmer
              _PwdField(
                ctrl: _confirmCtrl, label: 'Confirmer le nouveau mot de passe',
                show: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm),
                validator: (v) {
                  if (v != _newPwdCtrl.text) return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),

              const SizedBox(height: 8),

              // Conseils
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text('Conseils sécurité', style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: Colors.blue.shade700)),
                  ]),
                  const SizedBox(height: 6),
                  _Tip('Utilisez au moins 8 caractères'),
                  _Tip('Mélangez lettres, chiffres et symboles'),
                  _Tip('N\'utilisez pas votre date de naissance'),
                ]),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Modifier le mot de passe',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // ── Mot de passe oublié
          _sectionLabel('MOT DE PASSE OUBLIÉ'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Icon(Icons.email_outlined, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Réinitialisation par email',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Envoyer un lien à $email',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ])),
              TextButton(
                onPressed: _sendResetEmail,
                child: Text('Envoyer', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ]),
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

class _PwdField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PwdField({required this.ctrl, required this.label,
      required this.show, required this.onToggle, this.validator});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl, obscureText: !show, validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
          onPressed: onToggle,
        ),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      Icon(Icons.check_rounded, size: 14, color: Colors.blue.shade600),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
    ]),
  );
}