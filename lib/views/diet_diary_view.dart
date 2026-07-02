import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/diet_model.dart';
import '../controllers/diet_controller.dart';
import 'food_search_view.dart';
import 'food_details_view.dart';

class DietDiaryView extends StatefulWidget {
  const DietDiaryView({super.key});

  @override
  State<DietDiaryView> createState() => _DietDiaryViewState();
}

class _DietDiaryViewState extends State<DietDiaryView> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = context.read<DietController>().historySelectedDate;
  }

  void _moveMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dietProvider = context.watch<DietController>();

    final DateTime firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final DateTime lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    
    final int prefixEmptyCells = firstDayOfMonth.weekday - 1;
    final int totalDaysInMonth = lastDayOfMonth.day;
    
    final int totalCellsCount = prefixEmptyCells + totalDaysInMonth;
    final int structuralGridCount = (totalCellsCount / 7).ceil() * 7; 

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 🌟 Smash Fit Core Canvas Background
      appBar: AppBar(
        title: const Text("Diary Log", style: TextStyle(color: Color(0xFF233036), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF233036)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ELEVATED CALENDAR CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  // Month Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Color(0xFF233036)), 
                        onPressed: () => _moveMonth(-1)
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_focusedMonth),
                        style: const TextStyle(color: Color(0xFF233036), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Color(0xFF233036)), 
                        onPressed: () => _moveMonth(1)
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Days of the week row headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _WeekLabel("Mon"), _WeekLabel("Tue"), _WeekLabel("Wed"),
                      _WeekLabel("Thu"), _WeekLabel("Fri"), _WeekLabel("Sat"), _WeekLabel("Sun"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Self-adjusting Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: structuralGridCount, 
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemBuilder: (context, index) {
                      if (index < prefixEmptyCells) return const SizedBox.shrink();

                      final int dayNum = index - prefixEmptyCells + 1;
                      if (dayNum > totalDaysInMonth) return const SizedBox.shrink();

                      final DateTime cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                      final String token = "${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";
                      
                      final bool hasFood = dietProvider.datesWithFood.contains(token);
                      final bool isSelected = cellDate.year == dietProvider.historySelectedDate.year &&
                                              cellDate.month == dietProvider.historySelectedDate.month &&
                                              cellDate.day == dietProvider.historySelectedDate.day;

                      // 🔒 FUTURE LOCK BOUNDARY CHECK
                      final DateTime now = DateTime.now();
                      final DateTime todayMidnightCeiling = DateTime(now.year, now.month, now.day, 23, 59, 59);
                      final bool isFutureDay = cellDate.isAfter(todayMidnightCeiling);

                      return GestureDetector(
                        // 🔒 FUTURE LOCK: Disable selection if the day is in the future
                        onTap: isFutureDay ? null : () => dietProvider.updateHistoryDate(cellDate),
                        child: Opacity(
                          // 🔒 FUTURE LOCK: Fade out future grid cells cleanly
                          opacity: isFutureDay ? 0.30 : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2A9D8F) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected 
                                  ? Border.all(color: const Color(0xFF2A9D8F), width: 1)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$dayNum",
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF233036),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  height: 4,
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: hasFood 
                                        ? (isSelected ? Colors.white : const Color(0xFF2A9D8F))
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. MODERN HISTORICAL MACRO SNAPSHOT CARD (Only displays when food is tracked)
            if (dietProvider.historyCalories > 0) _buildHistorySnapshotCard(dietProvider),
            if (dietProvider.historyCalories > 0) const SizedBox(height: 20),

            // 3. TARGET CONTEXT TIMELINE LABEL
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(dietProvider.historySelectedDate),
                style: const TextStyle(color: Color(0xFF233036), fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),

            // 4. MODULAR SECTIONS LIST
            ...dietProvider.historyMeals.map((m) => _buildHistoryMealSection(m, dietProvider)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySnapshotCard(DietController provider) {
    final tdee = provider.targetCalories;
    final double pct = tdee > 0 ? (provider.historyCalories / tdee).clamp(0.0, 1.0) : 0.0;
    final maxP = provider.maxProtein.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 85,
                width: 85,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFEFEFEF),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2A9D8F)),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${provider.historyCalories}", style: const TextStyle(color: Color(0xFF233036), fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("of $tdee kcal", style: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              )
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildMiniBar("Protein", provider.historyProtein, maxP, Colors.orange),
                const SizedBox(height: 10),
                _buildMiniBar("Carbs", provider.historyCarbs, 250, Colors.blue),
                const SizedBox(height: 10),
                _buildMiniBar("Fat", provider.historyFat, 75, Colors.green),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniBar(String label, int val, double target, Color color) {
    double progress = target > 0 ? (val / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF233036), fontSize: 11, fontWeight: FontWeight.bold)),
            Text("${val}g", style: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress, 
            backgroundColor: const Color(0xFFEFEFEF), 
            valueColor: AlwaysStoppedAnimation(color), 
            minHeight: 5
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryMealSection(MealCategory m, DietController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: const Color(0xFF233036),
        collapsedIconColor: const Color(0xFF8B8B8B),
        shape: const Border(),
        title: Text(m.title, style: const TextStyle(color: Color(0xFF233036), fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text("${m.totalCalories} kcal", style: const TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.bold, fontSize: 13)),
        children: [
          const Divider(color: Color(0xFFEFEFEF), height: 1),
          if (m.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("No meals logged for this category", style: TextStyle(color: Color(0xFF8B8B8B), fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ...m.items.map((i) => _buildHistoryFoodTile(i, m.id, controller)).toList(),
          _buildHistoryAddButton(m.id, controller),
        ],
      ),
    );
  }

  Widget _buildHistoryFoodTile(FoodItem i, String mealId, DietController controller) {
    return Slidable(
      key: Key(i.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => controller.deleteFood(i.id),
            backgroundColor: const Color(0xFFE63946),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(i.name, style: const TextStyle(color: Color(0xFF233036), fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text("${i.amount}${i.unit} • P:${i.protein}g C:${i.carbs}g F:${i.fat}g", style: const TextStyle(fontSize: 12, color: Color(0xFF8B8B8B), fontWeight: FontWeight.w500)),
        trailing: IconButton(
          icon: const Icon(Icons.edit_note, color: Color(0xFF8B8B8B)),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FoodDetailsView(
              mealId: mealId, controller: controller, existingItem: i,
              ingredientData: {'id': i.externalId, 'name': i.name, 'calories': i.calories / i.amount, 'protein': i.protein / i.amount, 'carbs': i.carbs / i.amount, 'fat': i.fat / i.amount, 'serving': i.unit},
            )));
          },
        ),
      ),
    );
  }

  Widget _buildHistoryAddButton(String mealId, DietController controller) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => FoodSearchView(
              mealId: mealId, 
              controller: controller,
              specificTargetDate: controller.historySelectedDate, // 🌟 THE FIX: Pass the historical date
            )
          ));
        },
        icon: const Icon(Icons.add, size: 16),
        label: const Text("Add past meal", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2A9D8F),
          backgroundColor: const Color(0xFF2A9D8F).withAlpha(13), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  final String text;
  const _WeekLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35, 
      child: Text(
        text, 
        textAlign: TextAlign.center, 
        style: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 12, fontWeight: FontWeight.bold)
      ),
    );
  }
}