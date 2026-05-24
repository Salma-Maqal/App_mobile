import 'package:flutter/material.dart';

class DiabetesAnalyzer {
  static String riskLevel(int gi) {
    if (gi < 55) return "Faible";
    if (gi < 70) return "Moyen";
    return "Élevé";
  }

  static Color riskColor(int gi) {
    if (gi < 55) return Colors.green;
    if (gi < 70) return Colors.orange;
    return Colors.red;
  }

  static int diabeticScore({
    required int gi,
    required int glucides,
    required int calories,
  }) {
    int score = 100;
    score -= gi ~/ 2; // Pénalité IG
    score -= (glucides ~/ 3); // Pénalité glucides
    score -= (calories ~/ 25); // Pénalité calories
    return score.clamp(0, 100);
  }

  static String recommendation(int gi) {
    if (gi >= 70) {
      return "⚠️ Réduisez la portion. Ce repas peut provoquer une augmentation rapide de la glycémie.";
    }
    if (gi >= 55) {
      return "🟠 Consommation modérée. À équilibrer avec d'autres repas à faible IG.";
    }
    return "✅ Bon choix pour diabétiques. Faible impact glycémique.";
  }

  static String getAdvice(int gi, int calories) {
    if (gi >= 70 && calories > 500) {
      return "⚠️⚠️ Repas à risque élevé : IG élevé + calories élevées. Évitez ou réduisez fortement la portion.";
    }
    if (gi >= 70) {
      return "⚠️ IG élevé : Privilégiez une petite portion et accompagnez de fibres.";
    }
    if (gi < 55 && calories < 400) {
      return "🌟 Excellent choix ! Faible IG et calories modérées.";
    }
    return recommendation(gi);
  }
}
