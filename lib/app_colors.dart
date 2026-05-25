import 'package:flutter/material.dart';

class AppColors {
  // ── Palette originale (light) - conservée pour compatibilité ──
  static const c1 = Color(0xFFE7F5DC);
  static const c2 = Color(0xFFCFE1B9);
  static const c3 = Color(0xFFB6C99B);

  // ── Nouvelle palette "Medical Premium" (Bleu Santé / Confiance) ──
  
  /// Bleu médical profond - Couleur principale de confiance et d'autorité
  static const medicalBlue = Color(0xFF2B5B84);
  
  /// Violet moderne - Pour les données glycémiques et accents
  static const medicalPurple = Color(0xFF6C63FF);
  
  /// Bleu nuit doux - Pour le texte principal (plus lisible que le noir)
  static const nightBlue = Color(0xFF1E293B);
  
  /// Gris bleuté très clair - Fond d'écran (moins agressif que le blanc)
  static const lightBlueGray = Color(0xFFF4F7FA);
  
  /// Gris professionnel - Pour le texte secondaire
  static const professionalGrey = Color(0xFF64748B);
  
  /// Ambre - Pour les calories
  static const amber = Color(0xFFF59E0B);
  
  /// Rouge adouci - Pour le sucre (alertes glycémiques)
  static const softRed = Color(0xFFEF4444);
  
  /// Émeraude - Pour le sport et les succès
  static const emerald = Color(0xFF10B981);
  
  // ── Mapping sémantique moderne (Medical Premium) ──
  static const primary = medicalBlue;      // Couleur principale (Bleu médical)
  static const bg = lightBlueGray;         // Fond d'écran
  static const textDark = nightBlue;       // Texte principal
  static const textGrey = professionalGrey; // Texte secondaire
  static const accent = medicalPurple;      // Couleur d'accent (Glycémie)
  static const accentLight = Color(0xFFEEF2FF); // Accent clair
  
  // ── Couleurs pour les indicateurs spécifiques ──
  static const calories = amber;            // Calories (Ambre)
  static const sugar = softRed;             // Sucre (Rouge médical)
  static const sport = emerald;             // Sport (Émeraude)
  static const water = medicalBlue;         // Hydratation (Bleu)
  
  // ── Compatibilité avec l'ancien code ──
  static const sageGreen = medicalBlue;
  static const mintGreen = emerald;
  static const darkGreen = nightBlue;
  static const lightGreenBg = lightBlueGray;
  static const softGrey = professionalGrey;
  static const coral = medicalPurple;
  static const coralLight = Color(0xFFEEF2FF);
  static const c4 = medicalBlue;
  static const c5 = emerald;
  static const c6 = nightBlue;
  static const resedaGreen = medicalBlue;
  static const fernGreen = emerald;
  static const darkMoss = nightBlue;
  static const pakistanGreen = Color(0xFF0F172A);
  
  // ── Couleurs utilitaires ──
  static const white = Color(0xFFFFFFFF);
  static const error = softRed;
  static const warning = amber;
  static const success = emerald;
}