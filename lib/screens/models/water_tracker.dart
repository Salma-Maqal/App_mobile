import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/../app_colors.dart'; // تأكد من استيراد مسار ملف الألوان الصحيح

class WaterTracker extends StatelessWidget {
  const WaterTracker({super.key});

  Future<void> _addWater() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('water_logs')
          .add({
        'amount': 500, // كل ضغطة تضيف 500 مل كما في التصميم
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('water_logs')
          .snapshots(),
      builder: (context, snapshot) {
        int totalMl = 0;
        int completedGlasses = 0;
        const int targetGlasses = 5;

        if (snapshot.hasData) {
          completedGlasses = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            totalMl += (doc['amount'] as int);
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$completedGlasses of $targetGlasses glasses consumed', 
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                  const Icon(Icons.water_drop, color: AppColors.water),
                ],
              ),
              const SizedBox(height: 8),
              Text('${(totalMl / 1000).toStringAsFixed(1)}L / 2.5L', 
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(targetGlasses, (index) {
                  bool isDone = index < completedGlasses;
                  return GestureDetector(
                    onTap: () => isDone ? null : _addWater(),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDone ? AppColors.water : AppColors.accentLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDone ? Icons.check : Icons.water_drop, 
                            color: isDone ? AppColors.white : AppColors.water, 
                            size: 24
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(isDone ? "500ML" : "", style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}