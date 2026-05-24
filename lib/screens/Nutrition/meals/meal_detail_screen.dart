// lib/screens/Nutrition/meal_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../app_colors.dart';
import '../../../services/firestore_service.dart';
import '../../../screens/models/predefined_meal.dart';

class MealDetailScreen extends StatefulWidget {
  final PredefinedMeal meal;
  
  const MealDetailScreen({super.key, required this.meal});
  
  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  double _quantity = 100;
  bool _adding = false;
  
  @override
  Widget build(BuildContext context) {
    final scaledCalories = (widget.meal.calories * _quantity / 100).round();
    final scaledCarbs = widget.meal.carbs * _quantity / 100;
    final scaledProteins = widget.meal.proteins * _quantity / 100;
    final scaledFats = widget.meal.fats * _quantity / 100;
    
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.c6,
        elevation: 0,
        title: Text(
          widget.meal.name,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                image: widget.meal.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.meal.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.meal.imageUrl.isEmpty
                  ? const Center(
                      child: Icon(Icons.fastfood, size: 60, color: Colors.grey),
                    )
                  : null,
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.meal.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.meal.isDiabeticFriendly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✅ Diabetic Friendly',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (widget.meal.glycemicIndex > 60)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⚠️ Ce plat a un index glycémique élevé (${widget.meal.glycemicIndex}). À consommer avec modération.',
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  if (widget.meal.description.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.meal.description,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Quantity (grammes)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _quantity,
                          min: 50,
                          max: 500,
                          divisions: 9,
                          label: '${_quantity.round()}g',
                          activeColor: AppColors.c6,
                          onChanged: (value) => setState(() => _quantity = value),
                        ),
                      ),
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.c2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_quantity.round()}g',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Nutritional Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _NutrientRow(
                          label: '🔥 Calories',
                          value: '$scaledCalories kcal',
                          original: '${widget.meal.calories} kcal/100g',
                        ),
                        _NutrientRow(
                          label: '🍞 Glucides',
                          value: '${scaledCarbs.toStringAsFixed(1)} g',
                          original: '${widget.meal.carbs} g/100g',
                        ),
                        _NutrientRow(
                          label: '💪 Protéines',
                          value: '${scaledProteins.toStringAsFixed(1)} g',
                          original: '${widget.meal.proteins} g/100g',
                        ),
                        _NutrientRow(
                          label: '🥑 Lipides',
                          value: '${scaledFats.toStringAsFixed(1)} g',
                          original: '${widget.meal.fats} g/100g',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getGiColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getGiColor().withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.monitor_heart, color: _getGiColor(), size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Glycemic Index: ${widget.meal.glycemicIndex}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getGiColor(),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getGiAdvice(),
                                style: TextStyle(color: _getGiColor()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _adding ? null : _addToDiary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.c6,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _adding
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Add to my diary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getGiColor() {
    if (widget.meal.glycemicIndex < 55) return Colors.green;
    if (widget.meal.glycemicIndex < 70) return Colors.orange;
    return Colors.red;
  }
  
  String _getGiAdvice() {
    if (widget.meal.glycemicIndex < 55) {
      return 'Faible impact sur la glycémie. Bon choix pour les diabétiques.';
    } else if (widget.meal.glycemicIndex < 70) {
      return 'Impact glycémique modéré. À consommer avec modération.';
    } else {
      return 'Impact glycémique élevé. Surveillez votre glycémie après ce repas.';
    }
  }
  
  Future<void> _addToDiary() async {
    setState(() => _adding = true);
    
    try {
      await _firestoreService.addMealFromPredefined(widget.meal, _quantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final String value;
  final String original;
  final bool isLast;
  
  const _NutrientRow({
    required this.label,
    required this.value,
    required this.original,
    this.isLast = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                original,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}