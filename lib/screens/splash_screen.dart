 import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
void initState() {
  super.initState();

  _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

  _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

  _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

  _ctrl.forward();

  _checkAuth();
}
void _checkAuth() async {
  final user = FirebaseAuth.instance.currentUser;

  await Future.delayed(const Duration(milliseconds: 2600));

  if (!mounted) return;

  if (user == null) {
    // ❌ not logged in
    Navigator.pushReplacementNamed(context, '/welcome');
    return;
  }

  await user.reload();

  final refreshedUser = FirebaseAuth.instance.currentUser;

  if (refreshedUser != null && refreshedUser.emailVerified) {
    // 🔐 verified user
    Navigator.pushReplacementNamed(context, '/dashboard');
  } else {
    // 🟡 logged but not verified
    Navigator.pushReplacementNamed(context, '/verify');
  }
}
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062010),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('CalmSugar',
                    style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF4CAF50),
                        letterSpacing: 0.3)),
                const SizedBox(width: 4),
                SizedBox(
                  width: 58, height: 56,
                  child: CustomPaint(painter: _CubesPainter()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CubesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final s = Paint()
      ..color = Colors.white ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.026 ..strokeJoin = StrokeJoin.round ..strokeCap = StrokeCap.round;
    final c = Paint()
      ..color = Colors.white.withOpacity(0.45) ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.013 ..strokeCap = StrokeCap.round;
    double x(double v) => v / 96 * w; double y(double v) => v / 92 * h;
    void f(List<List<double>> p) {
      final path = Path()..moveTo(x(p[0][0]), y(p[0][1]));
      for (int i = 1; i < p.length; i++) path.lineTo(x(p[i][0]), y(p[i][1]));
      path.close(); canvas.drawPath(path, s);
    }
    f([[48,4],[62,12],[48,20],[34,12]]); f([[34,12],[48,20],[48,36],[34,28]]); f([[62,12],[48,20],[48,36],[62,28]]);
    canvas.drawLine(Offset(x(48),y(4)),Offset(x(48),y(20)),c);
    f([[22,46],[40,56],[22,66],[4,56]]); f([[4,56],[22,66],[22,86],[4,76]]); f([[40,56],[22,66],[22,86],[40,76]]);
    canvas.drawLine(Offset(x(22),y(46)),Offset(x(22),y(66)),c);
    f([[74,46],[92,56],[74,66],[56,56]]); f([[56,56],[74,66],[74,86],[56,76]]); f([[92,56],[74,66],[74,86],[92,76]]);
    canvas.drawLine(Offset(x(74),y(46)),Offset(x(74),y(66)),c);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}