import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  bool _loading = false;
  String? _message;

  Future<void> _checkVerification() async {
    setState(() => _loading = true);

    User? user = FirebaseAuth.instance.currentUser;

    await user?.reload();

    user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null && user.emailVerified) {
      setState(() => _loading = false);

      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      setState(() {
        _loading = false;
        _message = "Email pas encore vérifié.";
      });
    }
  }

  Future<void> _resendEmail() async {
    try {
      await FirebaseAuth.instance.currentUser
          ?.sendEmailVerification();

      setState(() {
        _message = "Email envoyé ✔";
      });
    } catch (e) {
      setState(() {
        _message = "Erreur d'envoi email";
      });
    }
  }




Timer? _timer;

@override
void initState() {
  super.initState();

  _timer = Timer.periodic(const Duration(seconds: 5), (_) {
    _checkVerification();
  });
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          WaveHeader(
            title: 'Vérification',
            onBack: () => Navigator.pop(context),
          ),

          const SizedBox(height: 60),

          const Icon(Icons.mark_email_read,
              size: 80, color: AppColors.c6),

          const SizedBox(height: 20),

          const Text(
            "Vérifiez votre email",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          const Text(
            "Cliquez sur le lien envoyé dans votre email",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          if (_message != null)
            Text(
              _message!,
              style: const TextStyle(color: AppColors.error),
            ),

          const SizedBox(height: 20),

          PrimaryButton(
            label: "J'ai vérifié",
            loading: _loading,
            onPressed: _checkVerification,
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: _resendEmail,
            child: const Text("Renvoyer email"),
          ),
        ],
      ),
    );
  }
}