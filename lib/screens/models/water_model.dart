import 'package:cloud_firestore/cloud_firestore.dart';

class WaterModel {
  final String? id;
  final String dateKey;
  final int glasses;

  const WaterModel({
    this.id,
    required this.dateKey,
    required this.glasses,
  });

  // ─── Firestore ──────────────────────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'dateKey': dateKey,
      'glasses': glasses,
    };
  }

  factory WaterModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return WaterModel(
      id: doc.id,
      dateKey: map['dateKey'] ?? '',
      glasses: (map['glasses'] as num?)?.toInt() ?? 0,
    );
  }

  // ─── copyWith ───────────────────────────────────────────────
  WaterModel copyWith({
    String? id,
    String? dateKey,
    int? glasses,
  }) {
    return WaterModel(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      glasses: glasses ?? this.glasses,
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

  /// باش تزيد كأس وحدة
  WaterModel addGlass() => copyWith(glasses: glasses + 1);

  /// باش تنقص كأس وحدة — ما تنزلش من 0
  WaterModel removeGlass() => copyWith(glasses: (glasses - 1).clamp(0, 99));

  /// dateKey من DateTime مباشرة
  static String keyFromDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// dateKey ديال اليوم
  static String get todayKey => keyFromDate(DateTime.now());

  @override
  String toString() => 'WaterModel(dateKey: $dateKey, glasses: $glasses)';
}
