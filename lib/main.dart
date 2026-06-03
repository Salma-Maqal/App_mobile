import 'package:flutter/services.dart';
import 'user_session.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/health_info_screen.dart';
import 'screens/companion_info_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_companion_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/add_meal_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/Mon_Profil_screen.dart';
import 'screens/Nutification_screen.dart';
import 'screens/securite_screen.dart';
// ✅ Nouveaux screens
import 'screens/sport_screen.dart';
import 'screens/glycemie_screen.dart';
import 'screens/hydratation_screen.dart';
import 'screens/historique_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- N'oublie pas d'ajouter le package
import 'user_session.dart';
// ... tes autres imports ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await UserSession().load();
  
  // Configuration propre de la barre d'état
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const CalmSugarApp());
}

class CalmSugarApp extends StatelessWidget {
  const CalmSugarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Définition d'une palette de couleurs cohérente
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D531A),
      primary: const Color(0xFF2D531A),
      secondary: const Color(0xFF789C65),
      surface: const Color(0xFFF0F7E8),
    );

    return MaterialApp(
      title: 'CalmSugar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF0F7E8),
        
        // Application de la police professionnelle sur toute l'app
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        
        // Style global des boutons pour un look plus pro
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/':                 (_) => const SplashScreen(),
        '/welcome':          (_) => const WelcomeScreen(),
        '/login':            (_) => const LoginScreen(),
        '/signup':           (_) => const SignUpScreen(),
        '/health-info':      (_) => const HealthInfoScreen(),
        '/companion-info':   (_) => const CompanionInfoScreen(),
        '/dashboard':        (_) => const DashboardScreen(),
        '/add-companion':    (_) => const AddCompanionScreen(),
        '/verify':           (_) => const VerifyScreen(),
        '/forgot-password':  (_) => const ForgotPasswordScreen(),
        '/add-meal':         (_) => const AddMealScreen(),
        '/nutrition':        (_) => const NutritionScreen(),
        '/profile':          (_) => const MonProfilScreen(),
        '/notifications':    (_) => const NotificationsScreen(),
        '/securite':         (_) => const SecuriteScreen(),
        '/sport':            (_) => const SportScreen(),
        '/glycemie':         (_) => const GlycemieScreen(),
        '/hydratation':      (_) => const HydratationScreen(),
       // '/historique':       (_) => const HistoriqueScreen(),
      },
    );
  }
}