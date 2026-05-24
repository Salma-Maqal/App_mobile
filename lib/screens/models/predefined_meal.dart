// lib/screens/models/predefined_meal.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PredefinedMeal {
  final String? id;
  final String name;              // اسم الطبق
  final String mealType;          // breakfast, lunch, dinner, snack
  final String category;          // Soups, Moroccan, Salads, etc.
  final String imageUrl;          // رابط الصورة
  final int calories;             // السعرات الحرارية لكل 100g
  final double proteins;          // البروتينات لكل 100g
  final double carbs;             // الكربوهيدرات لكل 100g
  final double fats;              // الدهون لكل 100g
  final int glycemicIndex;        // المؤشر الجلايسيمي
  final bool isDiabeticFriendly;  // مناسب لمرضى السكري؟
  final String description;       // وصف الطبق

  const PredefinedMeal({
    this.id,
    required this.name,
    required this.mealType,
    required this.category,
    required this.imageUrl,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.glycemicIndex,
    required this.isDiabeticFriendly,
    required this.description,
  });

  // ─── To Firestore ───
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'mealType': mealType,
      'category': category,
      'imageUrl': imageUrl,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'glycemicIndex': glycemicIndex,
      'isDiabeticFriendly': isDiabeticFriendly,
      'description': description,
    };
  }

  // ─── From Firestore ───
  factory PredefinedMeal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PredefinedMeal(
      id: doc.id,
      name: data['name'] ?? '',
      mealType: data['mealType'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      proteins: (data['proteins'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fats: (data['fats'] as num?)?.toDouble() ?? 0.0,
      glycemicIndex: (data['glycemicIndex'] as num?)?.toInt() ?? 0,
      isDiabeticFriendly: data['isDiabeticFriendly'] ?? false,
      description: data['description'] ?? '',
    );
  }

  // ─── CopyWith ───
  PredefinedMeal copyWith({
    String? id,
    String? name,
    String? mealType,
    String? category,
    String? imageUrl,
    int? calories,
    double? proteins,
    double? carbs,
    double? fats,
    int? glycemicIndex,
    bool? isDiabeticFriendly,
    String? description,
  }) {
    return PredefinedMeal(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      glycemicIndex: glycemicIndex ?? this.glycemicIndex,
      isDiabeticFriendly: isDiabeticFriendly ?? this.isDiabeticFriendly,
      description: description ?? this.description,
    );
  }
}