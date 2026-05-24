// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/models/meal_model.dart';
import '../screens/models/water_model.dart';
import '../screens/models/predefined_meal.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ─── Collections ───
  CollectionReference get _mealsCol =>
      _firestore.collection('users').doc(_uid).collection('meals');

  CollectionReference get _waterCol =>
      _firestore.collection('users').doc(_uid).collection('water');

  // ✅ Collection للأطباق المعرفة مسبقاً
  CollectionReference get _predefinedMealsCol =>
      _firestore.collection('predefined_meals');

  // ═══════════════════════════════════════════════════════════
  // MEALS (الموجود سابقاً - ما تمسحش)
  // ═══════════════════════════════════════════════════════════

  Future<void> addMeal(MealModel meal) async {
    try {
      await _mealsCol.add(meal.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du repas: $e');
    }
  }

  Future<void> updateMeal(MealModel meal) async {
    if (meal.id == null) throw Exception('ID manquant pour la mise à jour');
    try {
      await _mealsCol.doc(meal.id).update(meal.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la modification du repas: $e');
    }
  }

  Future<void> deleteMeal(String id) async {
    try {
      await _mealsCol.doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du repas: $e');
    }
  }

  Stream<List<MealModel>> getMeals() {
    return _mealsCol
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MealModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<MealModel>> getMealsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _mealsCol
        .where('addedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('addedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MealModel.fromFirestore(doc))
            .toList());
  }

  Stream<int> getCaloriesForDate(DateTime date) {
    return getMealsForDate(date).map(
      (meals) => meals.fold(0, (sum, meal) => sum + meal.calories),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WATER (الموجود سابقاً - ما تمسحش)
  // ═══════════════════════════════════════════════════════════

  Future<void> setWater(WaterModel water) async {
    try {
      await _waterCol.doc(water.dateKey).set(water.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de l\'eau: $e');
    }
  }

  Stream<WaterModel?> getWater(String dateKey) {
    return _waterCol.doc(dateKey).snapshots().map((doc) {
      if (!doc.exists) return null;
      return WaterModel.fromFirestore(doc);
    });
  }

  Stream<WaterModel?> getWaterToday() {
    return getWater(WaterModel.todayKey);
  }

  // ═══════════════════════════════════════════════════════════
  // NEW: PREDEFINED MEALS (جديد - للإضافة فقط)
  // ═══════════════════════════════════════════════════════════

  /// جيب جميع الأطباق predefined
  Stream<List<PredefinedMeal>> getAllPredefinedMeals() {
    return _predefinedMealsCol.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PredefinedMeal.fromFirestore(doc)).toList());
  }

  /// جيب الأطباق حسب النوع (breakfast, lunch, dinner, snack)
  Stream<List<PredefinedMeal>> getMealsByType(String mealType) {
    return _predefinedMealsCol
        .where('mealType', isEqualTo: mealType)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PredefinedMeal.fromFirestore(doc)).toList());
  }

  /// جيب الأطباق حسب النوع والتصنيف
  Stream<List<PredefinedMeal>> getMealsByTypeAndCategory(String mealType, String category) {
    return _predefinedMealsCol
        .where('mealType', isEqualTo: mealType)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PredefinedMeal.fromFirestore(doc)).toList());
  }

  /// جيب التصنيفات المتاحة لنوع معين
  Future<List<String>> getCategoriesForMealType(String mealType) async {
    final snapshot = await _predefinedMealsCol
        .where('mealType', isEqualTo: mealType)
        .get();
    
    final categories = snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .map((data) => data['category'] as String)
        .toSet()
        .toList();
    
    return categories;
  }

  /// تحويل وتخزين وجبة من PredefinedMeal إلى MealModel (للمستخدم)
  Future<void> addMealFromPredefined(PredefinedMeal meal, double quantity) async {
    try {
      final userMeal = MealModel(
        type: _convertMealType(meal.mealType),
        iconName: _getIconForMealType(meal.mealType),
        platName: meal.name,
        platEmoji: _getEmojiForCategory(meal.category),
        glucides: meal.carbs * quantity / 100,
        quantite: quantity,
        calories: (meal.calories * quantity / 100).round(),
        addedAt: DateTime.now(),
      );
      await _mealsCol.add(userMeal.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du repas: $e');
    }
  }

  // ─── Helper methods ───
  String _convertMealType(String type) {
    switch (type) {
      case 'breakfast': return 'Petit-déjeuner';
      case 'lunch': return 'Déjeuner';
      case 'dinner': return 'Dîner';
      case 'snack': return 'Goûter';
      default: return 'Repas';
    }
  }

  String _getIconForMealType(String type) {
    switch (type) {
      case 'breakfast': return 'free_breakfast';
      case 'lunch': return 'lunch_dining';
      case 'dinner': return 'dinner_dining';
      case 'snack': return 'cookie';
      default: return 'restaurant';
    }
  }

  String _getEmojiForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'soups': return '🥣';
      case 'moroccan meals': return '🍲';
      case 'salads': return '🥗';
      case 'fish': return '🐟';
      case 'meat': return '🍖';
      case 'drinks': return '🥤';
      case 'healthy food': return '🥑';
      default: return '🍽️';
    }
  }
}