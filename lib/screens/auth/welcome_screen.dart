import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.c6,
      body: Stack(
        children: [
          // Wave bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(height: h * 0.52, color: AppColors.bg),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.08),
                  Text('CalmSugar',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic, color: AppColors.c2)),
                  SizedBox(height: h * 0.28),
                  const Text('Welcome',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800,
                          color: Color.fromARGB(255, 38, 47, 19))),
                  const SizedBox(height: 14),
                  Text('Gérez votre diabète au quotidien.\nSuivez, analysez et restez en bonne santé.',
                      style: TextStyle(fontSize: 15, color: const Color.fromARGB(255, 6, 6, 6), height: 1.6)),
                  SizedBox(height: h * 0.06),

                  // Diagramme: Non (pas de compte) → Créer compte
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.c6,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Sign Up to page',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Diagramme: Oui (a un compte) → Se connecter
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Text('Déjà un compte ? Se connecter',
                        style: TextStyle(
                            color: const Color.fromARGB(255, 23, 35, 2), fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.c5)),
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

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.25);
    path.cubicTo(size.width * 0.25, 0, size.width * 0.75, size.height * 0.12, size.width, size.height * 0.05);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override bool shouldReclip(_WaveClipper o) => false;
}
