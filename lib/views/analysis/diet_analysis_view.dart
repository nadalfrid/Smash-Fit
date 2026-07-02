// lib/views/analysis/diet_analysis_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/diet_controller.dart';
import '../../controllers/analysis/diet_analysis_controller.dart'; 
import '../../models/diet_analysis_model.dart';
import '../../services/ai_coaching_service.dart';
import '../../models/diet_model.dart';

class DietAnalysisView extends StatefulWidget {
  const DietAnalysisView({super.key});

  @override
  State<DietAnalysisView> createState() => _DietAnalysisViewState();
}

class _DietAnalysisViewState extends State<DietAnalysisView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dietController = context.read<DietController>();
      context.read<DietAnalysisController>().runNutritionAnalysis(dietController);
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysisController = context.watch<DietAnalysisController>();
    final dietController = context.watch<DietController>(); 
    
    final DietAnalysisModel? data = analysisController.dietAnalysisData;
    final int targetCalories = dietController.targetCalories;
    final int targetProtein = dietController.maxProtein;

    if (analysisController.isLoading || data == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B1FA9)),
        ),
      );
    }

    final String status = data.statusLabel;
    final int avgCalories = data.averageDailyCalories;
    final int avgProtein = data.averageDailyProtein;
    final int daysLogged = data.daysLoggedCount;

    Color badgeColor;
    IconData badgeIcon;
    switch (status) {
      case 'Consistent Deficit':
        badgeColor = Colors.orange;
        badgeIcon = Icons.local_fire_department;
        break;
      case 'Consistent Surplus':
        badgeColor = Colors.teal;
        badgeIcon = Icons.add_chart;
        break;
      case 'Holding Steady':
        badgeColor = Colors.blue;
        badgeIcon = Icons.balance;
        break;
      case 'Unstable Intake':
      default:
        badgeColor = Colors.redAccent;
        badgeIcon = Icons.warning_rounded;
    }

    return RefreshIndicator(
      color: const Color(0xFF8B1FA9),
      onRefresh: () => analysisController.runNutritionAnalysis(dietController),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DYNAMIC NUTRISHIFT STATUS BADGE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(badgeIcon, color: badgeColor, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Based on $daysLogged days of logging over the last week.",
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. EMBEDDED standalone DIET AI COACH INSIGHT WIDGET
            _buildDietAiCoachingCard(analysisController, dietController),
            const SizedBox(height: 20),

            // 3. METRIC COMPARISON SUMMARY SHEET WITH SYNCHRONIZED CHARTS
            const Text(
              "7-Day Intake Averages vs Goals",
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            
            // --- Calorie Card & Chart Stack ---
            _buildMetricRow(
              label: "Daily Energy Intake",
              avgValue: "$avgCalories kcal",
              targetValue: "$targetCalories kcal",
              isWarning: status == 'Unstable Intake',
            ),
            const SizedBox(height: 6),
            _buildMacroBarChart(
              logs: data.dailyLogs,
              targetValue: targetCalories,
              isCalorie: true,
            ),
            
            const SizedBox(height: 20),
            
            // --- Protein Card & Chart Stack ---
            _buildMetricRow(
              label: "Daily Protein Intake",
              avgValue: "$avgProtein g",
              targetValue: "${dietController.maxProtein}g max target",
              isWarning: avgProtein < 50 && daysLogged > 0,
            ),
            const SizedBox(height: 6),
            _buildMacroBarChart(
              logs: data.dailyLogs,
              targetValue: targetProtein,
              isCalorie: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietAiCoachingCard(DietAnalysisController controller, DietController dietController) {
    const Color smashFitPurple = Color(0xFF8B1FA9);
    final textContent = controller.dietAnalysisData?.dietCoachingTip;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[900]!, const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: smashFitPurple.withOpacity(0.15), spreadRadius: 0, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFE9D5FF), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "SMASH FIT DIET STRATEGY",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFE9D5FF), letterSpacing: 0.8),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  controller.dietAnalysisData?.statusLabel.toUpperCase() ?? 'NO DATA',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF472B6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.isAiLoading) ...[
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE9D5FF)),
                ),
                SizedBox(width: 12),
                Text(
                  "Coach Gemini is optimizing nutrition parameters...",
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            )
          ] else if (textContent != null) ...[
            Text(
              textContent,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: smashFitPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 2,
                ),
                icon: const Icon(Icons.bolt, size: 16, color: Color(0xFFE9D5FF)),
                label: const Text("GENERATE DIET COACH INSIGHT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                onPressed: () {
                  final aiService = context.read<AICoachingService>();
                  final user = dietController.userProfile;

                  if (user != null) {
                    final double currentW = user.weight.toDouble();
                    double? targetWeight; 

                    controller.triggerNutritionAiUpdate(
                      aiService: aiService,
                      userName: user.name,
                      age: user.age,
                      gender: user.gender.name, 
                      currentWeight: currentW,
                      targetWeight: targetWeight, 
                      targetCalories: dietController.targetCalories,
                      targetProtein: dietController.maxProtein,
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String avgValue,
    required String targetValue,
    required bool isWarning,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? Colors.redAccent.withOpacity(0.3) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                "Your Avg: $avgValue",
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            "Goal: $targetValue",
            style: const TextStyle(color: Color(0xFF8B1FA9), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // 🌟 MODERNIZED: Custom Native Dependent Bar Chart Widget
  // =====================================================================
  Widget _buildMacroBarChart({
    required List<DailyDietLog> logs,
    required int targetValue,
    required bool isCalorie,
  }) {
    // Defensive Coding: Calculate the peak logged value to scale heights dynamically
    double peakValue = targetValue.toDouble();
    for (var log in logs) {
      final double currentVal = (isCalorie ? log.totalCalories : log.totalProtein).toDouble();
      if (currentVal > peakValue) {
        peakValue = currentVal;
      }
    }

    const double maxChartHeight = 110.0;
    final DateTime today = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          // 1. CHART AREA FRAME
          Container(
            height: maxChartHeight + 20, 
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              // 🌟 FIXED: ALWAYS generate exactly 7 slots, no matter how many logs exist
              children: List.generate(7, (index) {
                
                // index 0 = 6 days ago (Far Left), index 6 = 0 days ago / Today (Far Right)
                int daysAgo = 6 - index; 
                DateTime barDate = today.subtract(Duration(days: daysAgo));

                // 🌟 Match the specific calendar date to the logs list safely
                DailyDietLog? matchedLog;
                for (var log in logs) {
                  if (log.date.year == barDate.year &&
                      log.date.month == barDate.month &&
                      log.date.day == barDate.day) {
                    matchedLog = log;
                    break;
                  }
                }

                // If a log exists for this day, use its data. If not, safely default to 0.0
                final double actualValue = matchedLog != null
                    ? (isCalorie ? matchedLog.totalCalories : matchedLog.totalProtein).toDouble()
                    : 0.0;
                
                double complianceRatio = targetValue > 0 ? (actualValue / targetValue) : 0.0;
                double heightPercentage = peakValue > 0 ? (actualValue / peakValue) : 0.0;
                double calculatedBarHeight = heightPercentage * maxChartHeight;
                
                if (calculatedBarHeight < 6.0 && actualValue > 0) {
                  calculatedBarHeight = 6.0;
                }

                Color barColor;
                if (complianceRatio < 0.50) {
                  barColor = const Color(0xFFEF4444); 
                } else if (complianceRatio < 1.0) {
                  barColor = const Color(0xFFF59E0B); 
                } else {
                  barColor = const Color(0xFF2A9D8F); 
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Only show the floating number if the user actually logged food that day
                    if (actualValue > 0)
                      Text(
                        actualValue.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.w800, 
                          color: Color(0xFF1E293B),
                        ),
                      )
                    else 
                      const SizedBox(height: 12), // Keep spacing consistent when empty
                      
                    const SizedBox(height: 6),
                    
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      width: 24, 
                      // If actualValue is 0, height becomes 0, rendering an empty space!
                      height: actualValue > 0 ? calculatedBarHeight : 0, 
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),   
                          topRight: Radius.circular(6),  
                          bottomLeft: Radius.zero,       
                          bottomRight: Radius.zero,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Divider(
              color: Color(0xFFF1F5F9), 
              thickness: 2, 
              height: 12,
            ),
          ),
          
          // 3. X-AXIS TIMELINE ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              int daysAgo = 6 - index; 
              DateTime barDate = today.subtract(Duration(days: daysAgo));
              String dayLabel = _getWeekdayAbbreviation(barDate.weekday);
              
              return SizedBox(
                width: 24, 
                child: Text(
                  dayLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w700, 
                    color: Color(0xFF64748B),
                    letterSpacing: 0.1,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Translates international integer index systems to concise local interface headers
  String _getWeekdayAbbreviation(int weekday) {
    switch (weekday) {
      case DateTime.monday: return "Mon";
      case DateTime.tuesday: return "Tue";
      case DateTime.wednesday: return "Wed";
      case DateTime.thursday: return "Thu";
      case DateTime.friday: return "Fri";
      case DateTime.saturday: return "Sat";
      case DateTime.sunday: return "Sun";
      default: return "";
    }
  }
}