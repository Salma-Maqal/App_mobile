import 'package:flutter/material.dart';

class AppColors {
  // ── Palette originale (light)
  static const c1 = Color(0xFFE7F5DC);
  static const c2 = Color(0xFFCFE1B9);
  static const c3 = Color(0xFFB6C99B);

  // ── Nouvelle palette (image de référence)
  static const resedaGreen   = Color(0xFF6E8649); // 110, 134, 73
  static const fernGreen     = Color(0xFF477023); //  71, 112, 35
  static const darkMoss      = Color(0xFF2D531A); //  45,  83, 26
  static const pakistanGreen = Color(0xFF0D330E); //  13,  51, 14
  static const darkGreen     = Color(0xFF071E07); //   7,  30,  7

  // ── Mapping sémantique (remplace c4 / c5 / c6)
  static const c4 = resedaGreen;
  static const c5 = fernGreen;
  static const c6 = darkMoss;

  static const bg       = Color(0xFFF0F7E8); // blanc verdâtre doux
  static const primary  = darkMoss;
  static const white    = Color(0xFFFFFFFF);
  static const textDark = pakistanGreen;
  static const textGrey = fernGreen;
  static const error    = Color(0xFFD32F2F);
}