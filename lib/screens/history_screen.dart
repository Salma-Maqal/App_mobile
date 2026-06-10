import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';

const double kGlucidesObjectifJour = 200.0;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<double> _glucidesData = [];
  List<String> _dateLabels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('meals')
          .where('userId', isEqualTo: user.uid)
          .get();

      final Map<String, double> dailyData = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['timestamp1'] as Timestamp?;
        if (ts != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(ts.toDate());
          final gluc = (data['glucides'] ?? 0) as num;
          dailyData[dateKey] = (dailyData[dateKey] ?? 0) + gluc.toDouble();
        }
      }
      
      final sortedKeys = dailyData.keys.toList()..sort();
      
      setState(() {
        _glucidesData = sortedKeys.map((k) => dailyData[k]!).toList();
        _dateLabels = sortedKeys.map((k) {
          final parsedDate = DateTime.parse(k);
          return DateFormat('dd/MM').format(parsedDate); // Format simple ex: 07/06
        }).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Mon Historique", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.medicalBlue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  const Text(
                    "Évolution de mes glucides",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),
                  _buildSimpleChart(),
                  const SizedBox(height: 24),
                  _buildRecommendationsCard(), // Nouvelle section de conseils automatiques
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    double totalAujourdhui = _glucidesData.isNotEmpty ? _glucidesData.last : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          GlucideGauge(current: totalAujourdhui, goal: kGlucidesObjectifJour),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Aujourd'hui", style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
              Text(
                "${totalAujourdhui.toInt()}g / ${kGlucidesObjectifJour.toInt()}g", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSimpleChart() {
    if (_glucidesData.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Text("Aucune donnée enregistrée."),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: _glucidesData.length > 1 ? (_glucidesData.length - 1).toDouble() : 1,
          minY: 0,
          maxY: (kGlucidesObjectifJour * 1.3),
          
          // Ligne d'objectif claire
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: kGlucidesObjectifJour,
              color: AppColors.softRed.withOpacity(0.8),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => "Limite (${kGlucidesObjectifJour.toInt()}g)",
                style: const TextStyle(color: AppColors.softRed, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          ]),

          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < _dateLabels.length) {
                    return Text(_dateLabels[index], style: const TextStyle(color: AppColors.textGrey, fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) => Text("${value.toInt()}g", style: const TextStyle(color: AppColors.textGrey, fontSize: 9)),
              ),
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots: List.generate(_glucidesData.length, (i) => FlSpot(i.toDouble(), _glucidesData[i])),
              color: AppColors.medicalPurple,
              barWidth: 3,
              isCurved: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false), // Supprimé le dégradé pour faire plus simple
            ),
          ],
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // ── ANALYSE ET RECOMMANDATIONS AUTOMATIQUES ──
  Widget _buildRecommendationsCard() {
    double totalAujourdhui = _glucidesData.isNotEmpty ? _glucidesData.last : 0;
    
    String messageTitle = "";
    String messageBody = "";
    Color cardColor = Colors.green.shade50;
    Color iconColor = Colors.green;
    IconData icon = Icons.check_circle_outline;

    // Logique d'analyse simple
    if (totalAujourdhui == 0) {
      messageTitle = "Aucun repas aujourd'hui";
      messageBody = "Ajoutez vos premiers repas pour recevoir une analyse de votre charge glucidique.";
      cardColor = Colors.grey.shade100;
      iconColor = Colors.grey;
      icon = Icons.restaurant_menu;
    } else if (totalAujourdhui > kGlucidesObjectifJour) {
      messageTitle = "Attention : Glucides élevés !";
      messageBody = "Vous avez dépassé votre limite de ${kGlucidesObjectifJour.toInt()}g. Pour le prochain repas, privilégiez des protéines et des légumes verts pour stabiliser votre insuline.";
      cardColor = Colors.red.shade50;
      iconColor = AppColors.softRed;
      icon = Icons.warning_amber_rounded;
    } else if (totalAujourdhui > (kGlucidesObjectifJour * 0.8)) {
      messageTitle = "Proche de votre limite";
      messageBody = "Vous êtes presque à votre maximum. Optez pour des collations pauvres en sucre (comme des amandes ou un yaourt nature) si vous avez une faim tardive.";
      cardColor = Colors.orange.shade50;
      iconColor = Colors.orange;
      icon = Icons.info_outline;
    } else {
      messageTitle = "Excellent contrôle !";
      messageBody = "Votre consommation est parfaitement maîtrisée. Votre courbe est stable, ce qui évite les pics de glycémie soudains. Continuez ainsi !";
      cardColor = Colors.green.shade50;
      iconColor = Colors.green;
      icon = Icons.thumb_up_alt_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messageTitle,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: iconColor),
                ),
                const SizedBox(height: 6),
                Text(
                  messageBody,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlucideGauge extends StatelessWidget {
  final double current;
  final double goal;
  const GlucideGauge({super.key, required this.current, required this.goal});

  @override
  Widget build(BuildContext context) {
    double percentage = (current / goal).clamp(0.0, 1.0);
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CircularProgressIndicator(value: 1.0, strokeWidth: 6, color: Color(0xFFF4F7FA)),
          CircularProgressIndicator(
            value: percentage,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            strokeWidth: 6,
            strokeCap: StrokeCap.round,
          ),
          Text("${current.toInt()}g", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}