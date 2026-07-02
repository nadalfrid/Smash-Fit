// lib/controllers/analysis/diet_analysis_controller.dart

import 'package:flutter/material.dart';
import '../../models/diet_analysis_model.dart';
import '../../models/diet_model.dart';
import '../../services/analysis_service.dart';
import '../../services/ai_coaching_service.dart'; 
import '../diet_controller.dart';

class DietAnalysisController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAiLoading = false;
  DietAnalysisModel? _dietAnalysisData;
  
  // 🌟 NEW: Track the last user context to prevent cross-account state leaks
  String? _lastAnalyzedUsername; 

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  bool get isAiLoading => _isAiLoading;
  DietAnalysisModel? get dietAnalysisData => _dietAnalysisData;

  /// Orchestrates the 7-day macro nutrition aggregation pipeline.
  Future<void> runNutritionAnalysis(DietController dietController) async {
    _isLoading = true;
    notifyListeners();

    try {
      final DateTime now = DateTime.now();
      
      // 🌟 FIXED: Strip away the hours and minutes to lock 'today' to exactly 00:00:00 midnight
      final DateTime startOfToday = DateTime(now.year, now.month, now.day);
      
      // Go back exactly 6 full days to create a perfect 7-day calendar window (including today)
      final DateTime sevenDaysAgo = startOfToday.subtract(const Duration(days: 6));

      // 1. Ingest raw log datasets from the precise calendar data window
      final List<FoodItem> rawFoodLogs = await dietController.getDietLogsInWindow(sevenDaysAgo, now);

      // 2. Delegate 100% of the mathematical trend analysis to the AnalysisService
      final Map<String, dynamic> report = AnalysisService.analyzeDietMacroTrend(
        rawFoodItems: rawFoodLogs,
        dailyCalorieTarget: dietController.targetCalories,
        targetProteinFloor: dietController.maxProtein,
      );

      // 🌟 Step 2.5: Scavenge current user name to verify session boundaries
      final String currentUserName = dietController.userProfile?.name ?? "Fitness Enthusiast";
      
      // If the username switched, force existingTip to be NULL to wipe the stale cache!
      final String? existingTip = (_lastAnalyzedUsername == currentUserName)
          ? _dietAnalysisData?.dietCoachingTip
          : null;
          
      // Update our tracking token to the current user
      _lastAnalyzedUsername = currentUserName;

      // 3. Package the properties into our type-safe State Model
      _dietAnalysisData = DietAnalysisModel(
        statusLabel: report['status'] ?? 'No Data',
        averageDailyCalories: report['averageDailyCalories'] ?? 0,
        averageDailyProtein: report['averageDailyProtein'] ?? 0,
        daysLoggedCount: report['daysLoggedCount'] ?? 0,
        dailyLogs: List<DailyDietLog>.from(report['dailyLogs'] ?? []),
        dietCoachingTip: existingTip, // 🌟 Safe: Now dynamically wiped if user accounts swap!
      );
    } catch (e) {
      debugPrint("🎯 Error processing independent nutrition macro tracking controller: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  /// Manually executes the cloud Generative AI coaching logic strictly for the nutrition track.
  Future<void> triggerNutritionAiUpdate({
    required AICoachingService aiService,
    required String userName,
    required int age,
    required String gender,
    required double currentWeight,
    required double? targetWeight,
    required int targetCalories,
    required int targetProtein,
  }) async {
    if (_dietAnalysisData == null) return;
    
    _isAiLoading = true;
    notifyListeners();

    try {
      String generatedTip = await aiService.fetchAdaptiveNutritionStrategy(
        statusLabel: _dietAnalysisData!.statusLabel,
        avgDailyCalories: _dietAnalysisData!.averageDailyCalories,
        targetCalories: targetCalories,
        avgDailyProtein: _dietAnalysisData!.averageDailyProtein,
        targetProtein: targetProtein,
        daysAnalyzed: _dietAnalysisData!.daysLoggedCount,
        userName: userName,
        age: age,
        gender: gender,
        currentWeight: currentWeight,
        targetWeight: targetWeight,
      );
      
      _dietAnalysisData = _dietAnalysisData!.copyWith(dietCoachingTip: generatedTip);
    } catch (e) {
      debugPrint("🎯 Nutrition AI pipeline error: $e");
    } finally {
      _isAiLoading = false;
      notifyListeners();
    }
  }
}