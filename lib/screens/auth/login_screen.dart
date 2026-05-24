import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  void _login() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
    setState(() {
      _loading = false;
      _error = 'Veuillez remplir tous les champs.';
    });
    return;
  }

  try {
    final userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );

    final user = userCredential.user;

    if (user == null) {
      setState(() {
        _loading = false;
        _error = "Erreur de connexion.";
      });
      return;
    }
   // ✅ IMPORTANT: Load existing data from SharedPreferences
    final session = UserSession();
    await session.load();
    
    // If nom/prenom are empty, try to get from Firestore (for existing users)
    if (session.nom.isEmpty && session.prenom.isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          await session.save(
            nom: data['nom'] ?? '',
            prenom: data['prenom'] ?? '',
            email: user.email,
          );
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/dashboard');
    
  } on FirebaseAuthException catch (e) {
    setState(() {
      _loading = false;
      if (e.code == 'user-not-found') {
        _error = "Aucun utilisateur trouvé.";
      } else if (e.code == 'wrong-password') {
        _error = "Mot de passe incorrect.";
      } else {
        _error = e.message;
      }
    });
  }


}

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          WaveHeader(title: 'Se Connecter', onBack: () => Navigator.pop(context)),
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
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  AuthField(
                    label: 'E-mail', controller: _emailCtrl,
                    hint: 'exemple@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  AuthField(
                    label: 'Mot de passe', controller: _passwordCtrl,
                    hint: '••••••••', obscure: _obscure,
                    prefixIcon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textGrey, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ✅ "Mot de passe oublié ?" — maintenant cliquable
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color: AppColors.c5,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),
                  PrimaryButton(label: 'Se connecter', onPressed: _login, loading: _loading),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: Divider(color: AppColors.c3, thickness: 1)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ou', style: TextStyle(color: AppColors.textGrey, fontSize: 13))),
                    Expanded(child: Divider(color: AppColors.c3, thickness: 1)),
                  ]),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                          children: [
                            const TextSpan(text: "Pas encore de compte ? "),
                            TextSpan(text: "S'inscrire",
                                style: TextStyle(color: AppColors.c6, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
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