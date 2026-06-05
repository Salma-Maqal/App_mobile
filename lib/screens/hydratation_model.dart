import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';

class HydrationModal {
  static Future<void> show(BuildContext context) async {
    int selectedAmount = 250; // ml par défaut
    
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '💧 Hydratation',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Quantité d\'eau (ml)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAmountButton(150, selectedAmount, setState),
                    _buildAmountButton(250, selectedAmount, setState),
                    _buildAmountButton(500, selectedAmount, setState),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAmountButton(750, selectedAmount, setState),
                    _buildAmountButton(1000, selectedAmount, setState),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveHydration(context, selectedAmount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.water,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Ajouter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Afficher le total d'aujourd'hui
                FutureBuilder<int>(
                  future: _getTodayWaterTotal(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final total = snapshot.data!;
                      final percent = (total / 2000 * 100).clamp(0, 100);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total aujourd\'hui :',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '$total ml / 2000 ml',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.water,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percent / 100,
                            backgroundColor: AppColors.bg,
                            color: AppColors.water,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
  
  static Widget _buildAmountButton(
    int amount,
    int selectedAmount,
    StateSetter setState,
  ) {
    final isSelected = selectedAmount == amount;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => setState(() => selectedAmount = amount),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.water : AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.water : Colors.transparent,
              ),
            ),
            child: Text(
              '$amount ml',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  static Future<void> _saveHydration(BuildContext context, int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }
    
    try {
      // Sauvegarder dans Firestore
      await FirebaseFirestore.instance.collection('water_intake').add({
        'userId': user.uid,
        'amount': amount,
        'timestamp': Timestamp.now(),
        'date': DateTime.now().toIso8601String().split('T').first, // YYYY-MM-DD
        'method': 'manual',
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $amount ml ajoutés à votre hydratation'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context); // Fermer le modal
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  static Future<int> _getTodayWaterTotal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('water_intake')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: today)
          .get();
      
      int total = 0;
      for (var doc in querySnapshot.docs) {
        total += (doc.data()['amount'] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      debugPrint('Erreur getTodayWaterTotal: $e');
      return 0;
    }
  }
}