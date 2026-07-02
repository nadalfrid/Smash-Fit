// lib/views/analysis/diet_insight_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/analysis/diet_insight_controller.dart';
import '../../controllers/diet_controller.dart'; // Change to match your exact shared diet controller name
import '../../models/diet_insight_model.dart';

class DietInsightView extends StatefulWidget {
  final DietController sharedDietController;

  const DietInsightView({
    super.key,
    required this.sharedDietController,
  });

  @override
  State<DietInsightView> createState() => _DietInsightViewState();
}

class _DietInsightViewState extends State<DietInsightView> {
  final List<String> _monthsShort = ["Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Automatically pull initial baseline calculations on layout creation pass
      context.read<DietInsightController>().recalculateDailyNutritionInsight(widget.sharedDietController);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DietInsightController>();
    final insight = controller.currentDayInsight;
    const Color smashFitPurple = Color(0xFF8B1FA9);

    final currentFoodPool = widget.sharedDietController.historyMeals;
    
    if (insight == null && currentFoodPool.isNotEmpty && !controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.recalculateDailyNutritionInsight(widget.sharedDietController);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          
          // 1. HORIZONTAL 7-DAY CALENDAR STRIP PILL BAR
          SizedBox(
            height: 66,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: controller.calendarStripDays.length,
              itemBuilder: (context, index) {
                final dayDate = controller.calendarStripDays[index];
                final bool isSelected = DateUtils.isSameDay(dayDate, controller.selectedDate);
                final String weekdayShort = _getShortWeekday(dayDate.weekday);

                final DateTime now = DateTime.now();
                final DateTime todayMidnightCeiling = DateTime(now.year, now.month, now.day, 23, 59, 59);
                final bool isFutureDay = dayDate.isAfter(todayMidnightCeiling);

                return GestureDetector(
                  // 🚫 Disable tapping if it is a future date
                  onTap: isFutureDay ? null : () => controller.selectActiveDate(dayDate, widget.sharedDietController),
                  child: Opacity(
                    // 🌫️ Fade out future dates so the user knows they are locked
                    opacity: isFutureDay ? 0.35 : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 58,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? smashFitPurple : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                        boxShadow: isSelected ? [
                          BoxShadow(color: smashFitPurple.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekdayShort,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${dayDate.day}",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // MAIN CARD WORKSPACE CONTENT SHEET
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator(color: smashFitPurple))
                : insight == null
                    ? _buildErrorPlaceholder()
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        children: [
                          // 2. MASTER COMPLIANCE BADGE CARD LAYER
                          _buildMasterComplianceCard(insight),
                          
                          const SizedBox(height: 16),
                          
                          // 3. SINGLE DAY SECTION TITLE
                          Text(
                            "${insight.date.day}-${_monthsShort[insight.date.month - 1]} Logged Intakes vs Daily Profile Targets",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                          
                          const SizedBox(height: 12),

                          // 4. ENERGY CALORIES INTAKE BOUNDS ROW CARD
                          _buildNutrientMetricBlock(
                            icon: Icons.battery_charging_full_outlined,
                            iconColor: const Color(0xFF10B981),
                            title: "Caloric Intake Bounds",
                            primaryLine: "Logged: ${insight.loggedCalories} kcal",
                            secondaryLine: "Target Baseline: ${insight.targetCalories} kcal",
                            footerLine: "Variance: ${insight.calorieVariance >= 0 ? '+' : ''}${insight.calorieVariance} kcal (${insight.calorieStatusLabel})",
                            footerColor: insight.calorieVariance > 200 ? const Color(0xFF0D9488) : (insight.calorieVariance < -400 ? const Color(0xFFEA580C) : const Color(0xFF64748B)),
                          ),

                          const SizedBox(height: 12),

                          // 5. PROTEIN CELLULAR RECOVERY FLOOR ROW CARD
                          _buildNutrientMetricBlock(
                            icon: Icons.science_outlined,
                            iconColor: const Color(0xFF2563EB),
                            title: "Cellular Recovery Floor",
                            primaryLine: "Logged: ${insight.loggedProtein} g",
                            secondaryLine: "Recovery Floor: ${insight.targetProteinFloor} g",
                            footerLine: "Status: ${insight.proteinStatusLabel} (${insight.proteinDelta >= 0 ? '+' : ''}${insight.proteinDelta}g relative to baseline)",
                            footerColor: insight.proteinDelta >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),

                          const SizedBox(height: 12),

                          // 6. BALANCE ROW SEGMENTS COLUMN (CARBS & FATS DUAL SUB-ROW WIDGET)
                          _buildBalancedMacrosDualRow(insight),

                          const SizedBox(height: 16),

                          // 7. END-OF-DAY NUTRITIONAL MANAGEMENT COMPLIANCE CARD
                          _buildAiCoachCard(context, controller, insight),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterComplianceCard(DietDailyInsightModel insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.themeColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: insight.themeColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(insight.statusIconMarker, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.badgeTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            insight.badgeExplanation,
            style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.4, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientMetricBlock({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String primaryLine,
    required String secondaryLine,
    required String footerLine,
    required Color footerColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(primaryLine, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              Text(secondaryLine, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),
          Text(
            footerLine,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: footerColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancedMacrosDualRow(DietDailyInsightModel insight) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniMacroCell(label: "Carbs Logged", value: "${insight.loggedCarbs}g", icon: Icons.bakery_dining_outlined, color: const Color(0xFFD97706)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniMacroCell(label: "Fats Logged", value: "${insight.loggedFats}g", icon: Icons.eco_outlined, color: const Color(0xFF0284C7)),
        ),
      ],
    );
  }

  Widget _buildMiniMacroCell({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCoachCard(BuildContext context, DietInsightController controller, DietDailyInsightModel insight) {
    const Color smashFitPurple = Color(0xFF8B1FA9);
    final bool hasGenerated = controller.dailyAiInsightText != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B2F), // Sleek Dark Background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "SMASH FIT NUTRITION COACH",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  "${insight.date.day} ${_monthsShort[insight.date.month - 1]} LOG",
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Area
          if (insight.badgeTitle == "NO DATA LOGGED" || insight.badgeTitle == "ANALYSIS ONGOING")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: Colors.white54, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "LOG FOOD TO UNLOCK AI INSIGHTS",
                    style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            )
          else if (controller.isAiLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: smashFitPurple),
              ),
            )
          else if (!hasGenerated)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: smashFitPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => controller.generateDailyAiInsight(widget.sharedDietController),
                icon: const Icon(Icons.bolt, color: Colors.white, size: 20),
                label: const Text("GENERATE DAILY NUTRITION INSIGHT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            )
          else
            Text(
              controller.dailyAiInsightText!,
              style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  String _getShortWeekday(int weekday) {
    switch (weekday) {
      case 1: return "MON"; case 2: return "TUE"; case 3: return "WED";
      case 4: return "THU"; case 5: return "FRI"; case 6: return "SAT";
      default: return "SUN";
    }
  }

  Widget _buildErrorPlaceholder() {
    return const Center(
      child: Text(
        "Select a day above to initialize summary tracking.",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}