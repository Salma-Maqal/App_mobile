// lib/screens/Nutrition/meal_category_screen.dart
import 'package:flutter/material.dart';
import '../../../app_colors.dart';
import '../../../services/firestore_service.dart';
import '../../../screens/models/predefined_meal.dart';
import 'meal_detail_screen.dart';

class MealCategoryScreen extends StatefulWidget {
  final String mealType;
  final String title;
  
  const MealCategoryScreen({
    super.key,
    required this.mealType,
    required this.title,
  });
  
  @override
  State<MealCategoryScreen> createState() => _MealCategoryScreenState();
}

class _MealCategoryScreenState extends State<MealCategoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedCategory = 'all';
  List<String> _categories = ['all', 'Soups', 'Salads', 'Moroccan meals', 'Fish', 'Meat', 'Drinks', 'Healthy food'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.c6,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Categories tabs
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.c6 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.c6 : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Meals list
          Expanded(
            child: StreamBuilder<List<PredefinedMeal>>(
              stream: _firestoreService.getMealsByType(widget.mealType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No meals available'),
                  );
                }
                
                final meals = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return _MealItemCard(
                      meal: meal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MealDetailScreen(meal: meal),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MealItemCard extends StatelessWidget {
  final PredefinedMeal meal;
  final VoidCallback onTap;
  
  const _MealItemCard({
    required this.meal,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.c2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_menu, size: 30, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip(text: '${meal.calories} cal', color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      _InfoChip(text: '${meal.carbs.toStringAsFixed(0)}g carbs', color: Colors.blue),
                    ],
                  ),
                  if (meal.isDiabeticFriendly)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '✓ Diabetic Friendly',
                        style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            
            // Add button
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.c6,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color color;
  
  const _InfoChip({required this.text, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}