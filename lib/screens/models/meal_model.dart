// lib/screens/models/meal_model.dart (نرجعو كما كان)
import 'package:cloud_firestore/cloud_firestore.dart';

class MealModel {
  final String? id;
  final String type;
  final String iconName;
  final String platName;
  final String platEmoji;
  final double glucides;
  final double quantite;
  final int calories;
  final DateTime addedAt;

  const MealModel({
    this.id,
    required this.type,
    required this.iconName,
    required this.platName,
    required this.platEmoji,
    required this.glucides,
    required this.quantite,
    required this.calories,
    required this.addedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'iconName': iconName,
      'platName': platName,
      'platEmoji': platEmoji,
      'glucides': glucides,
      'quantite': quantite,
      'calories': calories,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealModel(
      id: doc.id,
      type: data['type'] ?? '',
      iconName: data['iconName'] ?? '',
      platName: data['platName'] ?? '',
      platEmoji: data['platEmoji'] ?? '',
      glucides: (data['glucides'] as num?)?.toDouble() ?? 0.0,
      quantite: (data['quantite'] as num?)?.toDouble() ?? 0.0,
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MealModel copyWith({
    String? id,
    String? type,
    String? iconName,
    String? platName,
    String? platEmoji,
    double? glucides,
    double? quantite,
    int? calories,
    DateTime? addedAt,
  }) {
    return MealModel(
      id: id ?? this.id,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      platName: platName ?? this.platName,
      platEmoji: platEmoji ?? this.platEmoji,
      glucides: glucides ?? this.glucides,
      quantite: quantite ?? this.quantite,
      calories: calories ?? this.calories,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}