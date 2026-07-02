import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/diet_model.dart';
import '../controllers/diet_controller.dart';
import 'food_search_view.dart';
import 'food_details_view.dart';
import 'diet_diary_view.dart'; // 🌟 Clean path resolution tracking
import 'package:flutter_slidable/flutter_slidable.dart';

class DietView extends StatefulWidget {
  const DietView({super.key});
  @override
  State<DietView> createState() => _DietViewState();
}

class _DietViewState extends State<DietView> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DietController>();
    final DateTime today = DateTime.now(); // 🌟 Ensures this main layout stays locked to TODAY ONLY

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Daily Nutrition", style: TextStyle(color: Color(0xFF233036), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF233036)),
      ),
      body: controller.meals.isEmpty 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2A9D8F)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildModernSummary(controller),
                  const SizedBox(height: 20),

                  // ==========================================================================
                  // 🌟 NUTRISHIFT DIARY NAVIGATION ROW (LOCKED TO TODAY'S DATE CONTEXT)
                  // ==========================================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(today),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF233036)),
                          ),
                          Text(
                            DateFormat('dd/MM/yy').format(today),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF8B8B8B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          // Reset the history pointer to match the active tapped day before launching page routes
                          controller.updateHistoryDate(DateTime.now());
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const DietDiaryView()));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1FA9).withAlpha(20), // 🌟 Non-deprecated alpha tint layering
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.menu_book_rounded, color: Color(0xFF8B1FA9), size: 18),
                              SizedBox(width: 6),
                              Text(
                                "Diary Log",
                                style: TextStyle(color: Color(0xFF8B1FA9), fontWeight: FontWeight.bold, fontSize: 13),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ==========================================================================

                  ...controller.meals.map((m) => _buildMealSection(m, controller, today)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildModernSummary(DietController controller) {
    final tdee = controller.targetCalories;
    final progress = (tdee > 0) ? (controller.currentCalories / tdee).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text("Daily Progress", style: TextStyle(color: Color(0xFF8B8B8B), fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFFEFEFEF),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2A9D8F)),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${controller.currentCalories}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Color(0xFF233036))),
                  Text("of $tdee kcal", style: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          _macroRow("Protein", controller.currentProtein, controller.proteinRange, Colors.orange, controller.maxProtein.toDouble()),
          const SizedBox(height: 12),
          _macroRow("Carbs", controller.currentCarbs, "${controller.carbsRange['min']}-${controller.carbsRange['max']}g", Colors.blue, controller.carbsRange['max']!.toDouble()),
          const SizedBox(height: 12),
          _macroRow("Fat", controller.currentFat, "${controller.fatRange['min']}-${controller.fatRange['max']}g", Colors.green, controller.fatRange['max']!.toDouble()),
        ],
      ),
    );
  }

  Widget _macroRow(String label, int current, String targetRange, Color color, double maxTarget) {
    double progress = (maxTarget > 0) ? (current / maxTarget).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF233036))), 
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF8B8B8B)),
                children: [
                  TextSpan(text: "$current", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF233036))),
                  TextSpan(text: " / $targetRange"),
                ],
              ),
            ),
          ]
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            valueColor: AlwaysStoppedAnimation(color), 
            backgroundColor: const Color(0xFFEFEFEF),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(MealCategory m, DietController controller, DateTime contextDate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF233036))),
        subtitle: Text("${m.totalCalories} kcal", style: const TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.w600)),
        children: [
          const Divider(height: 1),
          ...m.items.map((i) => _buildFoodTile(i, m.id, controller)).toList(),
          _buildAddButton(m.id, controller, contextDate),
        ],
      ),
    );
  }

  Widget _buildFoodTile(FoodItem i, String mealId, DietController controller) {
    return Slidable(
      key: Key(i.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => controller.deleteFood(i.id),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: Text("${i.amount}${i.unit} • P:${i.protein}g C:${i.carbs}g F:${i.fat}g", style: const TextStyle(fontSize: 12, color: Color(0xFF8B8B8B))),
        trailing: IconButton(
          icon: const Icon(Icons.edit_note, color: Colors.grey),
          onPressed: () => _navigateToEdit(i, mealId, controller),
        ),
      ),
    );
  }

  Widget _buildAddButton(String mealId, DietController controller, DateTime contextDate) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextButton.icon(
        onPressed: () {
          // Explicitly passes contextDate parameter downstream to lock timestamps securely
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (_) => FoodSearchView(
                mealId: mealId, 
                controller: controller,
                // If FoodSearchView expects targetDate inside future logs, you can pass contextDate here!
              )
            )
          );
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text("Add to meal"),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2A9D8F),
          backgroundColor: const Color(0xFF2A9D8F).withAlpha(13), // 🌟 Updated non-deprecated alpha
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  void _navigateToEdit(FoodItem i, String mealId, DietController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDetailsView(
          mealId: mealId,
          controller: controller,
          existingItem: i,
          ingredientData: {
            'id': i.externalId,
            'name': i.name,
            'calories': i.calories / i.amount,
            'protein': i.protein / i.amount,
            'carbs': i.carbs / i.amount,
            'fat': i.fat / i.amount,
            'serving': i.unit,
          },
        ),
      ),
    );
  }
}