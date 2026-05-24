import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../core/user_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nomCtrl      = TextEditingController();
  final _prenomCtrl   = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  String _role         = 'diabetique';
  bool _agreeTerms     = false;
  bool _loading        = false;
  String? _error;

  
void _signUp() async {
  setState(() => _error = null);

  if (!_agreeTerms) {
    setState(() => _error = "Veuillez accepter les conditions d'utilisation.");
    return;
  }

  if (_passCtrl.text != _confirmCtrl.text) {
    setState(() => _error = 'Les mots de passe ne correspondent pas.');
    return;
  }

  setState(() => _loading = true);

  try {
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    
    // ✅ IMPORTANT: Update displayName in Firebase Auth
    final fullName = '${_prenomCtrl.text.trim()} ${_nomCtrl.text.trim()}';
    await userCredential.user?.updateDisplayName(fullName);
    await userCredential.user?.reload();
    
    await userCredential.user!.sendEmailVerification();
    
    await UserSession().save(
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );

    // Also save to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
          'nom': _nomCtrl.text.trim(),
          'prenom': _prenomCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'fullName': fullName,
          'role': _role,
          'createdAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;

    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/verify');

  } on FirebaseAuthException catch (e) {
    setState(() {
      _loading = false;
      _error = e.message;
    });
  }
}

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          WaveHeader(title: "S'inscrire", onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  Row(children: [
                    Expanded(child: AuthField(label: 'Nom', controller: _nomCtrl, hint: 'Benali')),
                    const SizedBox(width: 12),
                    Expanded(child: AuthField(label: 'Prénom', controller: _prenomCtrl, hint: 'Sara')),
                  ]),
                  const SizedBox(height: 14),
                  AuthField(label: 'E-mail', controller: _emailCtrl,
                      hint: 'exemple@gmail.com', keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined),
                  const SizedBox(height: 14),
                  AuthField(label: 'Mot de passe', controller: _passCtrl,
                      hint: '••••••••', obscure: _obscurePass, prefixIcon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textGrey, size: 20),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      )),
                  const SizedBox(height: 14),
                  AuthField(label: 'Confirmer le mot de passe', controller: _confirmCtrl,
                      hint: '••••••••', obscure: _obscureConfirm, prefixIcon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textGrey, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      )),
                  const SizedBox(height: 18),
                  const Text('Votre rôle',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: RoleButton(
                      label: 'Diabétique', icon: Icons.monitor_heart_outlined,
                      selected: _role == 'diabetique',
                      onTap: () => setState(() => _role = 'diabetique'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: RoleButton(
                      label: 'Accompagnant', icon: Icons.people_outline,
                      selected: _role == 'accompagnant',
                      onTap: () => setState(() => _role = 'accompagnant'),
                    )),
                  ]),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: _agreeTerms ? AppColors.c6 : Colors.transparent,
                          border: Border.all(color: _agreeTerms ? AppColors.c6 : AppColors.c4, width: 1.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: _agreeTerms ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                          children: [
                            const TextSpan(text: "J'accepte les "),
                            TextSpan(text: "conditions d'utilisation",
                                style: const TextStyle(color: AppColors.c6, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: "S'inscrire", onPressed: _signUp, loading: _loading),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                          children: [
                            TextSpan(text: 'Déjà un compte ? '),
                            TextSpan(text: 'Se connecter',
                                style: TextStyle(color: AppColors.c6, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
