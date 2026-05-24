import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = "Veuillez saisir un email valide.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email envoyé 📩 Vérifiez votre boîte mail")),
      );

      Navigator.pop(context); // يرجع ل login

    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;

        if (e.code == 'user-not-found') {
          _error = "Aucun utilisateur trouvé.";
        } else {
          _error = e.message;
        }
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          WaveHeader(
            title: "Mot de passe oublié",
            onBack: () => Navigator.pop(context),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 20),

                  const Text(
                    "Entrez votre email pour recevoir un lien de réinitialisation.",
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),

                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),

                  AuthField(
                    label: 'E-mail',
                    controller: _emailCtrl,
                    hint: 'exemple@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 32),

                  PrimaryButton(
                    label: "Envoyer",
                    onPressed: _resetPassword,
                    loading: _loading,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}