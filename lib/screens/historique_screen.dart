/*import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8FF),
      appBar: AppBar(title: const Text("Historique Global")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard("Glycémie (mg/dL)", _buildGlucoseStream()),
          const SizedBox(height: 20),
          _buildCard("Nutrition (Calories/Macros)", _buildNutritionStream()),
          const SizedBox(height: 20),
          _buildCard("Activité Physique (Cal)", _buildSportStream()),
        ],
      ),
    );
  }

  Widget _buildCard(String title, Widget chart) => Container(
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Expanded(child: chart)]),
      );

  // 1. STREAM GLYCÉMIE
  Widget _buildGlucoseStream() => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('glycemie_entries').orderBy('timestamp', descending: true).limit(7).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final spots = snapshot.data!.docs.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble())).toList();
          return LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots, color: Colors.purple, isCurved: true)]));
        },
      );

  // 2. STREAM NUTRITION (PIE CHART - Glucides vs Lipides)
  Widget _buildNutritionStream() => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('meals').limit(1).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          return PieChart(PieChartData(sections: [
            PieChartSectionData(value: (data['glucides'] as num).toDouble(), title: 'Gluc', color: Colors.blue),
            PieChartSectionData(value: (data['lipides'] as num).toDouble(), title: 'Lip', color: Colors.orange),
          ]));
        },
      );

  // 3. STREAM SPORT
  Widget _buildSportStream() => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sport_entries').limit(5).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final bars = snapshot.data!.docs.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: (e.value['calories'] as num).toDouble(), color: Colors.green)])).toList();
          return BarChart(BarChartData(barGroups: bars));
        },
      );
}*/