import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'meal_model.dart';

class NutritionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream dynamique qui renvoie une liste d'objets 'Meal'
  Stream<List<Meal>> getMealsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('meals')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList());
  }

  // Calcul dynamique des statistiques pour une date donnée
  Map<String, int> getDailyStats(List<Meal> meals, DateTime date) {
    final dailyMeals = meals.where((m) => 
      m.timestamp.year == date.year && 
      m.timestamp.month == date.month && 
      m.timestamp.day == date.day
    ).toList();

    return {
      'calories': dailyMeals.fold(0, (sum, m) => sum + m.calories),
      'sugar': dailyMeals.fold(0, (sum, m) => sum + m.sugar),
      'count': dailyMeals.length,
    };
  }
}