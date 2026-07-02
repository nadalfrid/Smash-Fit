// lib/controllers/exercise/exercise_detail_controller.dart
import 'package:flutter/material.dart';
import '../../models/workout_models.dart';
import '../../services/exercise_service.dart';

class ExerciseDetailController extends ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();
  
  Exercise? exercise;
  bool isLoading = true;

  Future<void> loadExercise(String exerciseId) async {
    // Reset state before loading a new exercise
    isLoading = true;
    exercise = null;
    
    // Future optimization: We wrap this in a post-frame callback safety net in the view, 
    // but notifying listeners immediately is standard practice here.
    notifyListeners(); 

    try {
      exercise = await _exerciseService.fetchExerciseById(exerciseId);
    } catch (e) {
      debugPrint("Error fetching exercise details: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}