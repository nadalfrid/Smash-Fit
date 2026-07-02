/// A simple data model that stores the calculated history and progress 
/// stats for a single exercise, now updated with an AI Coaching Tip container slot.
class ExerciseAnalysisModel {
  final String exerciseId;
  final String exerciseName;
  final String targetMuscle; 
  
  // 1. Raw Historical Progress Data
  final List<DateTime> workoutDates;
  final List<double> estimatedOneRepMaxHistory;
  
  // 2. Calculated Metrics (Within the selected calendar window)
  final double bestWeightLIFTED;
  final int totalSetsLogged;
  final int totalSessionsCount;
  final double averageRepsPerSet;
  
  // 3. LiftShift-Inspired Progress Statuses
  final String statusLabel;       // e.g., "gaining", "plateauing", "losing", "new"
  final String confidenceLevel;   // e.g., "High Confidence", "Medium", "Low"
  final double progressPercentage; // e.g., +3.5 or -1.2

  // 🌟 NEW: Non-hardcoded string slot for Gemini's processed strategy text
  final String? aiCoachingTip;

  // Constructor
  ExerciseAnalysisModel({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetMuscle,
    required this.workoutDates,
    required this.estimatedOneRepMaxHistory,
    required this.bestWeightLIFTED,
    required this.totalSetsLogged,
    required this.totalSessionsCount,
    required this.averageRepsPerSet,
    required this.statusLabel,
    required this.confidenceLevel,
    required this.progressPercentage,
    this.aiCoachingTip, // Nullable optional property parameter
  });

  /// CopyWith method to update the AI Tip separately without rebuilding the entire data structure
  ExerciseAnalysisModel copyWith({String? aiCoachingTip}) {
    return ExerciseAnalysisModel(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      targetMuscle: targetMuscle,
      workoutDates: workoutDates,
      estimatedOneRepMaxHistory: estimatedOneRepMaxHistory,
      bestWeightLIFTED: bestWeightLIFTED,
      totalSetsLogged: totalSetsLogged,
      totalSessionsCount: totalSessionsCount,
      averageRepsPerSet: averageRepsPerSet,
      statusLabel: statusLabel,
      confidenceLevel: confidenceLevel,
      progressPercentage: progressPercentage,
      aiCoachingTip: aiCoachingTip ?? this.aiCoachingTip,
    );
  }

  /// Converts the calculated analytical facts into a clean JSON map.
  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      'target_muscle_group': targetMuscle,
      'total_sessions_in_window': totalSessionsCount,
      'total_sets_logged': totalSetsLogged,
      'best_weight_lifted_kg': bestWeightLIFTED,
      'average_reps_per_set': averageRepsPerSet,
      'calculated_progress_percentage': '$progressPercentage%',
      'progress_status_label': statusLabel,
      'data_confidence_level': confidenceLevel,
    };
  }
}