// lib/controllers/analysis/workout_insight_controller.dart

import 'package:flutter/material.dart';
import '../../models/workout_insight_model.dart';
import '../../models/workout_models.dart'; 
import '../history/workout_history_controller.dart';
import '../../services/analysis_service.dart';

class WorkoutInsightController extends ChangeNotifier {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30)); // Expanded to 30 days for broader default insight visibility
  DateTime _endDate = DateTime.now();
  DateTime? _selectedActiveDate;
  bool _isLoading = false;

  List<DateTime> _loggedWorkoutDates = []; 
  List<WorkoutInsightModel> _dailySessionsInsights = []; // 🟢 Changed from single instance to an array list to hold multiple logs per day

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  DateTime? get selectedActiveDate => _selectedActiveDate;
  bool get isLoading => _isLoading;
  List<DateTime> get loggedWorkoutDates => _loggedWorkoutDates;
  List<WorkoutInsightModel> get dailySessionsInsights => _dailySessionsInsights;

  Future<void> updateDateRange(DateTime start, DateTime end, WorkoutHistoryController historyController) async {
    _startDate = start;
    _endDate = end;
    _selectedActiveDate = null; 
    _dailySessionsInsights = [];
    notifyListeners();
    
    fetchAndCompileTimelineWindow(historyController);
  }

  /// 🟢 OPTIMIZED: Reads the full public 'allLogs' stream pool to catch May 19, June 6, June 8, etc.
  void fetchAndCompileTimelineWindow(WorkoutHistoryController historyController) {
    _isLoading = true;
    notifyListeners();

    try {
      // Read the raw unfiltered historical cache list directly
      final List<WorkoutLog> historicalPool = historyController.allLogs; 

      final List<WorkoutLog> workoutsInRange = historicalPool.where((workout) {
        return workout.startTime.isAfter(_startDate.subtract(const Duration(days: 1))) &&
               workout.startTime.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      if (workoutsInRange.isEmpty) {
        _loggedWorkoutDates = [];
        _selectedActiveDate = null;
        _dailySessionsInsights = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      workoutsInRange.sort((a, b) => a.startTime.compareTo(b.startTime));

      final List<DateTime> uniqueDatesWithWorkouts = [];
      for (var workout in workoutsInRange) {
        final dateKey = DateTime(workout.startTime.year, workout.startTime.month, workout.startTime.day);
        if (!uniqueDatesWithWorkouts.any((d) => DateUtils.isSameDay(d, dateKey))) {
          uniqueDatesWithWorkouts.add(dateKey);
        }
      }

      _loggedWorkoutDates = uniqueDatesWithWorkouts;

      if (_selectedActiveDate == null && _loggedWorkoutDates.isNotEmpty) {
        _selectedActiveDate = _loggedWorkoutDates.last;
      }

      if (_selectedActiveDate != null) {
        compileSingleDayWorkoutInsight(workoutsInRange);
      }
    } catch (error) {
      debugPrint("🎯 Error processing workout insight timeline: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectActiveDate(DateTime targetDate, List<WorkoutLog> historicalPool) {
    if (_selectedActiveDate != null && DateUtils.isSameDay(_selectedActiveDate!, targetDate)) return;
    
    _selectedActiveDate = targetDate;
    _isLoading = true;
    notifyListeners();

    final List<WorkoutLog> workoutsInRange = historicalPool.where((workout) {
      return workout.startTime.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             workout.startTime.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    compileSingleDayWorkoutInsight(workoutsInRange);
    _isLoading = false;
    notifyListeners();
  }

  /// 🟢 MULTI-LOG HANDLING ENGINE: Loops and stacks multiple separate session entries found on the same calendar block
  void compileSingleDayWorkoutInsight(List<WorkoutLog> completeWindowLogs) {
    if (_selectedActiveDate == null) return;

    final List<WorkoutLog> targetedDayLogs = completeWindowLogs.where((log) => 
      DateUtils.isSameDay(log.startTime, _selectedActiveDate!)
    ).toList();

    if (targetedDayLogs.isEmpty) {
      _dailySessionsInsights = [];
      return;
    }

    List<WorkoutInsightModel> parsedSessionsForDay = [];

    // Loop through ALL workouts recorded on this day instead of just calling .first
    for (int sessionIndex = 0; sessionIndex < targetedDayLogs.length; sessionIndex++) {
      final currentLog = targetedDayLogs[sessionIndex];

      final List<Map<String, dynamic>> structuralExercisesMapList = currentLog.exercises.map((e) {
        return {
          'name': e.exercise.name,
          'sets': e.sets.map((s) => {
            'weight': s.weight ?? 0.0,
            'reps': s.reps ?? 0,
            'isCompleted': s.isCompleted,
          }).where((s) => s['isCompleted'] == true).toList(), 
        };
      }).toList();

      final compiledGroups = AnalysisService.compileFullWorkoutInsight(structuralExercisesMapList);
      
      // If multiple workouts exist, differentiate them by adding index labels (e.g., Session 1, Session 2)
      final String suffixLabel = targetedDayLogs.length > 1 ? " (Session ${sessionIndex + 1})" : "";
      final String dynamicTitleName = "${_getFullWeekdayName(currentLog.startTime.weekday)} Training Block$suffixLabel";

      parsedSessionsForDay.add(WorkoutInsightModel(
        workoutTitle: dynamicTitleName,
        workoutDate: currentLog.startTime,
        exercisesData: compiledGroups,
      ));
    }

    _dailySessionsInsights = parsedSessionsForDay;
  }

  String _getFullWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return "Monday"; case 2: return "Tuesday"; case 3: return "Wednesday";
      case 4: return "Thursday"; case 5: return "Friday"; case 6: return "Saturday";
      default: return "Sunday";
    }
  }
}