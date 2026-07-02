// lib/models/diet_analysis_model.dart
import '../models/diet_model.dart';

class DietAnalysisModel {
  final String statusLabel;           // "Consistent Deficit", "Consistent Surplus", "Holding Steady", "Unstable Intake"
  final int averageDailyCalories;
  final int averageDailyProtein;
  final int daysLoggedCount;
  final List<DailyDietLog> dailyLogs;
  final String? dietCoachingTip;      // 🟢 Standalone field for pure nutrition AI advice

  DietAnalysisModel({
    required this.statusLabel,
    required this.averageDailyCalories,
    required this.averageDailyProtein,
    required this.daysLoggedCount,
    required this.dailyLogs,
    this.dietCoachingTip,
  });

  DietAnalysisModel copyWith({
    String? statusLabel,
    int? averageDailyCalories,
    int? averageDailyProtein,
    int? daysLoggedCount,
    List<DailyDietLog>? dailyLogs,
    String? dietCoachingTip,
  }) {
    return DietAnalysisModel(
      statusLabel: statusLabel ?? this.statusLabel,
      averageDailyCalories: averageDailyCalories ?? this.averageDailyCalories,
      averageDailyProtein: averageDailyProtein ?? this.averageDailyProtein,
      daysLoggedCount: daysLoggedCount ?? this.daysLoggedCount,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      dietCoachingTip: dietCoachingTip ?? this.dietCoachingTip,
    );
  }
}