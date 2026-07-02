// lib/controllers/workout/workout_controller.dart
import 'package:flutter/material.dart';
import '../../models/workout_models.dart';
import '../../models/workout_plan_model.dart';

class WorkoutController extends ChangeNotifier {
  List<WorkoutExercise> activeExercises = [];
  bool isWorkoutActive = false;
  String? editingLogId; 

  // ===============================
  // GETTERS (USED BY UI)
  // ===============================
  int get totalSets => activeExercises.fold(0, (sum, ex) => sum + ex.sets.length);

  double get totalVolume {
    double vol = 0;
    for (var ex in activeExercises) {
      for (var set in ex.sets) {
        if (set.isCompleted) {
          vol += (set.weight ?? 0) * (set.reps ?? 0);
        }
      }
    }
    return vol;
  }

  // ===============================
  // WORKOUT CONTROL
  // ===============================
  void startNewWorkout({List<RoutineExercise>? initialExercises}) {
    isWorkoutActive = true;
    activeExercises = [];
    editingLogId = null;

    if (initialExercises != null && initialExercises.isNotEmpty) {
      for (var routineExercise in initialExercises) {
        
        // 1. Parse prescribed strings (e.g., "4*8-12") to determine structural set size counts
        int totalSetsToBuild = 1; 
        int targetReps = 10;     
        
        try {
          final parts = routineExercise.prescribedSetsReps.split('*');
          if (parts.isNotEmpty) {
            totalSetsToBuild = int.tryParse(parts.first.trim()) ?? 1;
            final repPart = parts.last.split('-').first.trim();
            targetReps = int.tryParse(repPart) ?? 10;
          }
        } catch (_) {
          // Fallbacks handle cleanly without breaking loop continuity
        }

        // 2. Map routine template fields into a complete database-ready Exercise instance block
        final coreExerciseModel = Exercise(
          id: routineExercise.exerciseId.trim(), // 🟢 FIXED: Preserves the clean 4-digit API ID ("0757", "1323", etc.)
          name: routineExercise.name,
          targetMuscle: routineExercise.targetGroup,
          equipment: 'Gym Equipment', 
        );

        // 3. Generate the required tracking sets list with preset target counts
        final List<WorkoutSet> initializedSets = List.generate(
          totalSetsToBuild,
          (index) => WorkoutSet(
            id: "${DateTime.now().millisecondsSinceEpoch}_${routineExercise.name.hashCode}_$index",
            weight: 0.0,
            reps: targetReps,
            isCompleted: false,
          ),
        );

        // 4. Wrap everything inside a unified WorkoutExercise type container
        final sessionExercise = WorkoutExercise(
          exercise: coreExerciseModel,
          sets: initializedSets,
        );

        activeExercises.add(sessionExercise);
      }
    }

    notifyListeners();
  }

  void loadWorkoutForEditing(WorkoutLog log) {
    isWorkoutActive = true;
    editingLogId = log.id;
    activeExercises = List.from(log.exercises); 
    notifyListeners();
  }

  void endWorkoutSession() {
    isWorkoutActive = false;
    activeExercises = [];
    editingLogId = null;
    notifyListeners();
  }

  // ===============================
  // SET & EXERCISE MANIPULATION
  // ===============================
  void addExercisesFromSearch(List<Exercise> exercises) {
    for (var ex in exercises) {
      activeExercises.add(
        WorkoutExercise(
          exercise: ex,
          sets: [
            WorkoutSet(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              weight: 0,
              reps: 0,
            ),
          ],
        ),
      );
    }
    notifyListeners();
  }

  void addSet(int exerciseIndex) {
    final prevSet = activeExercises[exerciseIndex].sets.isNotEmpty
        ? activeExercises[exerciseIndex].sets.last
        : null;

    activeExercises[exerciseIndex].sets.add(
      WorkoutSet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weight: prevSet?.weight,
        reps: prevSet?.reps,
      ),
    );
    notifyListeners();
  }

  void removeSet(int exerciseIndex, int setIndex) {
    activeExercises[exerciseIndex].sets.removeAt(setIndex);
    notifyListeners();
  }

  void updateSet(int exerciseIndex, int setIndex, {double? weight, int? reps, bool? isCompleted}) {
    final set = activeExercises[exerciseIndex].sets[setIndex];
    if (weight != null) set.weight = weight;
    if (reps != null) set.reps = reps;
    if (isCompleted != null) set.isCompleted = isCompleted;
    notifyListeners();
  }

  void removeExercise(int exerciseIndex) {
    activeExercises.removeAt(exerciseIndex);
    notifyListeners();
  }

  bool validateWorkout() {
    for (var ex in activeExercises) {
      for (var set in ex.sets) {
        if ((set.weight ?? 0) < 0 || (set.reps ?? 0) < 0) return false;
      }
    }
    return true;
  }
}