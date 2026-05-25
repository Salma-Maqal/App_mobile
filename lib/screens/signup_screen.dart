import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import '../widgets/common_widgets.dart';
import '../user_session.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _role = 'diabetique';
  bool _agreeTerms = false;
  bool _loading = false;
  String? _error;

  void _signUp() async {
    setState(() {
      _error = null;
    });

    // Validation des champs requis
    if (_nomCtrl.text.trim().isEmpty ||
        _prenomCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() {
        _error = "Veuillez remplir tous les champs.";
      });
      return;
    }

    if (!_agreeTerms) {
      setState(() {
        _error = "Veuillez accepter les conditions d'utilisation.";
      });
      return;
    }

    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() {
        _error = 'Les mots de passe ne correspondent pas.';
      });
      return;
    }

    if (_passCtrl.text.length < 6) {
      setState(() {
        _error = 'Le mot de passe doit contenir au moins 6 caractères.';
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );

      await userCredential.user!.sendEmailVerification();

      // ── Sauvegarde dans UserSession avec le rôle ──
      await UserSession().save(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: _role, // 'diabetique' ou 'accompagnant'
      );

      if (!mounted) return;

      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, '/verify');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        if (e.code == 'email-already-in-use') {
          _error = "Cet email est déjà utilisé.";
        } else if (e.code == 'invalid-email') {
          _error = "Email invalide.";
        } else if (e.code == 'weak-password') {
          _error = "Mot de passe trop faible.";
        } else {
          _error = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Une erreur est survenue. Veuillez réessayer.";
      });
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          WaveHeader(
            title: "Créer un compte",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Titre d'accueil ──
                  Text(
                    'Rejoignez notre communauté',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre compte pour suivre votre santé en toute sérénité.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Message d'erreur stylisé ──
                  if (_error != null) _ErrorWidget(message: _error!),

                  // ── Formulaire ──
                  Row(
                    children: [
                      Expanded(
                        child: AuthField(
                          label: 'Nom',
                          controller: _nomCtrl,
                          hint: 'Benali',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AuthField(
                          label: 'Prénom',
                          controller: _prenomCtrl,
                          hint: 'Sara',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AuthField(
                    label: 'E-mail',
                    controller: _emailCtrl,
                    hint: 'exemple@email.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),

                  AuthField(
                    label: 'Mot de passe',
                    controller: _passCtrl,
                    hint: '••••••••',
                    obscure: _obscurePass,
                    prefixIcon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  const SizedBox(height: 16),

                  AuthField(
                    label: 'Confirmer le mot de passe',
                    controller: _confirmCtrl,
                    hint: '••••••••',
                    obscure: _obscureConfirm,
                    prefixIcon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section Rôle ──
                  Text(
                    'Votre profil',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: RoleButton(
                          label: 'Diabétique',
                          icon: Icons.monitor_heart_outlined,
                          selected: _role == 'diabetique',
                          onTap: () => setState(() => _role = 'diabetique'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RoleButton(
                          label: 'Accompagnant',
                          icon: Icons.people_outline,
                          selected: _role == 'accompagnant',
                          onTap: () => setState(() => _role = 'accompagnant'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Checkbox Conditions d'utilisation ──
                  _TermsCheckbox(
                    value: _agreeTerms,
                    onChanged: (value) => setState(() => _agreeTerms = value),
                  ),

                  const SizedBox(height: 32),

                  // ── Bouton d'inscription ──
                  PrimaryButton(
                    label: "S'inscrire",
                    onPressed: _signUp,
                    loading: _loading,
                  ),

                  const SizedBox(height: 24),

                  // ── Lien vers connexion ──
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                          children: [
                            const TextSpan(text: 'Déjà un compte ? '),
                            TextSpan(
                              text: 'Se connecter',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

// ─────────────────────────────────────────────
// Widget d'erreur moderne
// ─────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget pour la checkbox des conditions
// ─────────────────────────────────────────────
class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: value ? AppColors.primary : AppColors.textGrey,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: value
                ? const Icon(Icons.check, color: AppColors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
                children: [
                  const TextSpan(text: "J'accepte les "),
                  TextSpan(
                    text: "conditions d'utilisation",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
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