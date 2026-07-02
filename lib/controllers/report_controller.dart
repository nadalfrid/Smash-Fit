import 'package:flutter/material.dart';
import 'package:printing/printing.dart'; 
import 'package:provider/provider.dart';
import '../services/pdf_export_service.dart';
import '../models/user_model.dart';
import '../controllers/history/workout_history_controller.dart';
import '../controllers/workout/workout_questionnaire_controller.dart';
import '../controllers/diet_controller.dart';
import '../models/diet_model.dart';

enum ReportTimeframe { oneMonth, threeMonths, sixMonths, allTime }

/// A helper model to bundle baseline, current, and net change data for the PDF matrix
class TrendMetric {
  final String baseline;
  final String current;
  final String change;

  TrendMetric({
    required this.baseline,
    required this.current,
    required this.change,
  });

  /// Provides a clean fallback if there isn't enough historical data to establish a trend
  factory TrendMetric.empty() {
    return TrendMetric(
      baseline: "N/A",
      current: "N/A",
      change: "-",
    );
  }
}

class ReportController extends ChangeNotifier {
  ReportTimeframe _selectedTimeframe = ReportTimeframe.oneMonth;
  ReportTimeframe get selectedTimeframe => _selectedTimeframe;

  bool _includeWeightTrend = true;
  bool get includeWeightTrend => _includeWeightTrend;
  bool _includeBmiTrack = true;
  bool get includeBmiTrack => _includeBmiTrack;
  bool _includeCalories = true;
  bool get includeCalories => _includeCalories;
  bool _includeMacros = true;
  bool get includeMacros => _includeMacros;
  bool _includeTotalVolume = true;
  bool get includeTotalVolume => _includeTotalVolume;
  bool _includeTotalSets = true;
  bool get includeTotalSets => _includeTotalSets;
  bool _includeMuscleGroup = true;
  bool get includeMuscleGroup => _includeMuscleGroup;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  void setTimeframe(ReportTimeframe timeframe) { _selectedTimeframe = timeframe; notifyListeners(); }

  void toggleMetric(String metricKey) {
    switch (metricKey) {
      case 'weightTrend': _includeWeightTrend = !_includeWeightTrend; break;
      case 'bmiTrack': _includeBmiTrack = !_includeBmiTrack; break;
      case 'calories': _includeCalories = !_includeCalories; break;
      case 'macros': _includeMacros = !_includeMacros; break;
      case 'totalVolume': _includeTotalVolume = !_includeTotalVolume; break;
      case 'totalSets': _includeTotalSets = !_includeTotalSets; break;
      case 'muscleGroup': _includeMuscleGroup = !_includeMuscleGroup; break;
    }
    notifyListeners();
  }

  Future<void> generateReport(BuildContext context, UserModel user) async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime baselineStart;
      DateTime baselineEnd;
      DateTime currentStart;
      DateTime currentEnd = now;
      String timeframeString = "Last 1 Month";

      // 1. DYNAMIC TIMEFRAME PARTITIONING (Baseline vs Current)
      switch (_selectedTimeframe) {
        case ReportTimeframe.oneMonth:
          startDate = now.subtract(const Duration(days: 30));
          baselineStart = startDate;
          baselineEnd = startDate.add(const Duration(days: 7)); // Week 1
          currentStart = now.subtract(const Duration(days: 7)); // Week 4
          timeframeString = "Last 1 Month";
          break;
        case ReportTimeframe.threeMonths:
          startDate = now.subtract(const Duration(days: 90));
          baselineStart = startDate;
          baselineEnd = startDate.add(const Duration(days: 14)); // First 2 Weeks
          currentStart = now.subtract(const Duration(days: 14)); // Last 2 Weeks
          timeframeString = "Last 3 Months";
          break;
        case ReportTimeframe.sixMonths:
          startDate = now.subtract(const Duration(days: 180));
          baselineStart = startDate;
          baselineEnd = startDate.add(const Duration(days: 14));
          currentStart = now.subtract(const Duration(days: 14));
          timeframeString = "Last 6 Months";
          break;
        case ReportTimeframe.allTime:
          startDate = DateTime(2000); 
          baselineStart = startDate;
          baselineEnd = startDate.add(const Duration(days: 30));
          currentStart = now.subtract(const Duration(days: 30));
          timeframeString = "All Time";
          break;
      }

      final questionnaire = Provider.of<WorkoutQuestionnaireController>(context, listen: false);
      final workoutHistory = Provider.of<WorkoutHistoryController>(context, listen: false);
      final dietController = Provider.of<DietController>(context, listen: false);

      // 2. HELPER: Calculate Training for a specific isolated window
      Map<String, dynamic> calculateTraining(DateTime start, DateTime end) {
        final logs = workoutHistory.allLogs.where((log) => log.startTime.isAfter(start) && log.startTime.isBefore(end)).toList();
        double volume = 0; int sets = 0; Map<String, int> muscleTally = {};
        
        for (var log in logs) {
          for (var ex in log.exercises) {
            for (var set in ex.sets) {
              final bool hasTrackingData = (set.weight ?? 0) > 0 && (set.reps ?? 0) > 0;
              if (set.isCompleted || hasTrackingData) {
                sets++;
                volume += (set.weight ?? 0.0) * (set.reps ?? 0);
                if (ex.exercise.targetMuscle.isNotEmpty) {
                  String muscle = ex.exercise.targetMuscle.trim();
                  muscleTally[muscle] = (muscleTally[muscle] ?? 0) + 1;
                }
              }
            }
          }
        }
        String topMuscle = muscleTally.isEmpty ? "N/A" : muscleTally.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        return {'volume': volume, 'sets': sets, 'topMuscle': topMuscle};
      }

      // 3. HELPER: Calculate Diet for a specific window (Pre-filling 0s for accurate averages)
      Map<String, dynamic> calculateDiet(DateTime start, DateTime end, List<FoodItem> rawLogs) {
        Map<String, int> dailyCal = {};
        Map<String, int> dailyProt = {};
        
        int totalDaysInWindow = end.difference(start).inDays;
        if (totalDaysInWindow <= 0) totalDaysInWindow = 1;
        
        // Loop forces every calendar day to exist in the map, exposing zero-log days
        for (int i = 0; i <= totalDaysInWindow; i++) {
          DateTime day = start.add(Duration(days: i));
          String key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
          dailyCal[key] = 0;
          dailyProt[key] = 0;
        }
        
        final filteredLogs = rawLogs.where((food) => food.timestamp.isAfter(start) && food.timestamp.isBefore(end)).toList();
        for (var food in filteredLogs) {
          String key = "${food.timestamp.year}-${food.timestamp.month.toString().padLeft(2, '0')}-${food.timestamp.day.toString().padLeft(2, '0')}";
          if (dailyCal.containsKey(key)) {
            dailyCal[key] = dailyCal[key]! + food.calories;
            dailyProt[key] = dailyProt[key]! + food.protein;
          }
        }
        
        int totalDays = dailyCal.length;
        int hitDays = dailyCal.keys.where((k) => dailyProt[k]! >= (dietController.maxProtein * 0.8)).length;
        
        int sumCal = dailyCal.values.fold(0, (sum, val) => sum + val);
        int avgCal = totalDays > 0 ? (sumCal / totalDays).round() : 0;
        double consistency = totalDays > 0 ? (hitDays / totalDays) * 100 : 0.0;
        
        return {'avgCal': avgCal, 'consistency': consistency};
      }

      // 4. EXECUTE CALCULATIONS
      final allDietLogs = await dietController.getDietLogsInWindow(startDate, now);
      
      final baseTrain = calculateTraining(baselineStart, baselineEnd);
      // FIX: If All Time, query from the absolute startDate to now to capture everything
      final currTrain = _selectedTimeframe == ReportTimeframe.allTime 
          ? calculateTraining(startDate, now)
          : calculateTraining(currentStart, currentEnd);
      
      final baseDiet = calculateDiet(baselineStart, baselineEnd, allDietLogs);
      // FIX: For All Time diet, skip continuous mapping padding to show actual tracked averages
      Map<String, dynamic> currDiet;
      if (_selectedTimeframe == ReportTimeframe.allTime) {
        Map<String, int> dailyCal = {};
        Map<String, int> dailyProt = {};
        for (var food in allDietLogs) {
          String key = "${food.timestamp.year}-${food.timestamp.month}-${food.timestamp.day}";
          dailyCal[key] = (dailyCal[key] ?? 0) + food.calories.toInt();
          dailyProt[key] = (dailyProt[key] ?? 0) + food.protein.toInt();
        }
        int totalLoggedDays = dailyCal.length > 0 ? dailyCal.length : 1;
        int hitDays = dailyCal.keys.where((k) => dailyProt[k]! >= (dietController.maxProtein * 0.8)).length;
        currDiet = {
          'avgCal': (dailyCal.values.fold(0, (a, b) => a + b) / totalLoggedDays).round(),
          'consistency': (hitDays / totalLoggedDays) * 100
        };
      } else {
        currDiet = calculateDiet(currentStart, currentEnd, allDietLogs);
      }

      // 5. PACKAGE TREND METRICS
      final String activeGoal = questionnaire.selectedGoal ?? "General Fitness";

      final pdfService = PdfExportService();
      final pdfBytes = await pdfService.generateReport(
        timeframeText: timeframeString,
        activeGoal: activeGoal,
        weightTrend: TrendMetric(baseline: "${user.weight} kg", current: "${user.weight} kg", change: "-"),
        bmiText: TrendMetric(baseline: "-", current: "${user.bmi} (${user.bmiCategory})", change: "-"),
        avgCal: TrendMetric(baseline: "${baseDiet['avgCal']} kcal", current: "${currDiet['avgCal']} kcal", change: "-"),
        macroConsistency: TrendMetric(baseline: "${(baseDiet['consistency'] as double).toStringAsFixed(0)}%", current: "${(currDiet['consistency'] as double).toStringAsFixed(0)}%", change: "-"),
        totalVolume: TrendMetric(baseline: "${(baseTrain['volume'] as double).toStringAsFixed(0)} kg", current: "${(currTrain['volume'] as double).toStringAsFixed(0)} kg", change: "-"),
        totalSets: TrendMetric(baseline: "${baseTrain['sets']} sets", current: "${currTrain['sets']} sets", change: "-"),
        mostTrained: TrendMetric(baseline: "-", current: currTrain['topMuscle'] as String, change: "-"),
        includeWeightTrend: _includeWeightTrend,
        includeBmiTrack: _includeBmiTrack,
        includeCalories: _includeCalories,
        includeMacros: _includeMacros,
        includeTotalVolume: _includeTotalVolume,
        includeTotalSets: _includeTotalSets,
        includeMuscleGroup: _includeMuscleGroup,
      );

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: 'SMASH_FIT_Report.pdf');
    } catch (e) {
      debugPrint("Error compiling report metrics: $e");
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}