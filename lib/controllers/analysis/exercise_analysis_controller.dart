import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🟢 Added for on-demand fetch
import 'package:cloud_firestore/cloud_firestore.dart'; // 🟢 Added for on-demand fetch
import '../../models/exercise_analysis_model.dart';
import '../../models/workout_models.dart';
import '../../services/analysis_service.dart';
import '../../services/firebase_service.dart';
import '../../services/ai_coaching_service.dart'; 
import '../diet_controller.dart'; 

enum StrengthSortOrder { lowToHigh, highToLow }

class ExerciseAnalysisController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final AICoachingService _aiCoachingService = AICoachingService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  bool _isAiLoading = false; 
  ExerciseAnalysisModel? _analysisData;

  // --- SELECTION, FILTERING, & SORTING STATES ---
  String _selectedExerciseId = "";
  String _selectedExerciseName = "";
  String _searchQuery = "";
  StrengthSortOrder _currentSortOrder = StrengthSortOrder.highToLow;

  List<Map<String, dynamic>> _masterExercises = [];

  // Getters
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  bool get isAiLoading => _isAiLoading;
  ExerciseAnalysisModel? get analysisData => _analysisData;
  String get selectedExerciseId => _selectedExerciseId;
  StrengthSortOrder get currentSortOrder => _currentSortOrder;

  int get totalExercisesCount => _masterExercises.length;
  int get gainingCount => _masterExercises.where((e) => e['status'] == 'gaining').length;
  int get plateauingCount => _masterExercises.where((e) => e['status'] == 'plateauing').length;
  int get losingCount => _masterExercises.where((e) => e['status'] == 'losing').length;

  List<Map<String, dynamic>> get availableExercises {
    var filteredList = _masterExercises.where((ex) => 
      ex['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    if (_currentSortOrder == StrengthSortOrder.lowToHigh) {
      filteredList.sort((a, b) => (a['pct'] as double).compareTo(b['pct'] as double));
    } else {
      filteredList.sort((a, b) => (b['pct'] as double).compareTo(a['pct'] as double));
    }

    return filteredList;
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSortOrder(StrengthSortOrder order) {
    _currentSortOrder = order;
    notifyListeners();
  }

  /// Sets the currently active exercise card and loads details
  void selectExercise(String id, String name, DietController dietController) {
    _selectedExerciseId = id;
    _selectedExerciseName = name;
    notifyListeners();
    loadExerciseAnalysis(id, name, dietController);
  }

  /// Updates timeline calendar bounds and refreshes datasets
  void updateDateRange(DateTime start, DateTime end, DietController dietController) {
    // Lock start date to the absolute beginning of the day
    _startDate = DateTime(start.year, start.month, start.day);
    
    // Push end date to the absolute final millisecond of the day to capture all Firestore logs
    _endDate = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    
    notifyListeners();
    initAnalysisDashboard(dietController); 
  }

  /// Initializes or refreshes the entire analytics engine based on database logs
  Future<void> initAnalysisDashboard(DietController dietController) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<WorkoutLog> workouts = await _firebaseService.getWorkoutsInWindow(_startDate, _endDate);

      if (workouts.isEmpty) {
        _masterExercises = [];
        _analysisData = null;
        return;
      }

      final Map<String, List<Map<String, dynamic>>> temporaryExerciseGroupings = {};
      final Map<String, String> exerciseNames = {};
      final Map<String, String> exerciseMuscles = {};

      workouts.sort((a, b) => a.startTime.compareTo(b.startTime));

      for (var workout in workouts) {
        for (var ex in workout.exercises) {
          final String id = ex.exercise.id;
          if (id.isEmpty) continue;

          exerciseNames[id] = ex.exercise.name;
          exerciseMuscles[id] = ex.exercise.targetMuscle;

          final completedSets = ex.sets.where((s) => s.isCompleted).toList();
          if (completedSets.isEmpty) continue;

          double maxWeight = 0;
          for (var set in completedSets) {
            if ((set.weight ?? 0) > maxWeight) maxWeight = set.weight!;
          }

          temporaryExerciseGroupings.putIfAbsent(id, () => []);
          temporaryExerciseGroupings[id]!.add({
            'workoutDate': workout.startTime,
            'sets': completedSets.map((s) => {'weight': s.weight ?? 0.0, 'reps': s.reps ?? 0}).toList(),
            'maxWeight': maxWeight,
          });
        }
      }

      final List<Map<String, dynamic>> discoveredMasterList = [];

      temporaryExerciseGroupings.forEach((id, historyList) {
        final computedProgress = AnalysisService.analyzeExerciseProgress(
          exerciseId: id,
          exerciseName: exerciseNames[id] ?? 'Unknown',
          rawWorkoutSessions: List<Map<String, dynamic>>.from(historyList),
          startDate: _startDate,
          endDate: _endDate,
          targetMuscle: exerciseMuscles[id] ?? 'General',
        );

        discoveredMasterList.add({
          'id': id,
          'name': exerciseNames[id] ?? 'Unknown',
          'pct': computedProgress.progressPercentage,
          'status': computedProgress.statusLabel, 
          'muscle': exerciseMuscles[id] ?? 'General',
          'rawLogs': historyList,
        });
      });

      _masterExercises = discoveredMasterList;

      if (_masterExercises.isNotEmpty) {
        final checkActive = _masterExercises.any((e) => e['id'] == _selectedExerciseId);
        if (!checkActive) {
          _selectedExerciseId = _masterExercises.first['id'];
          _selectedExerciseName = _masterExercises.first['name'];
        }

        final activeTarget = _masterExercises.firstWhere((e) => e['id'] == _selectedExerciseId);
        
        _analysisData = AnalysisService.analyzeExerciseProgress(
          exerciseId: _selectedExerciseId,
          exerciseName: _selectedExerciseName,
          rawWorkoutSessions: List<Map<String, dynamic>>.from(activeTarget['rawLogs']),
          startDate: _startDate,
          endDate: _endDate,
          targetMuscle: activeTarget['muscle'],
        );

        _isLoading = false;
        notifyListeners();
      } else {
        _analysisData = null;
      }
    } catch (e) {
      debugPrint("Error initializing database analytics metrics layer: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes calculations specifically when a user selects a different exercise card from side sheets
  Future<void> loadExerciseAnalysis(String exerciseId, String name, DietController dietController) async {
    if (_masterExercises.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final targetEntry = _masterExercises.firstWhere((e) => e['id'] == exerciseId);

      _analysisData = AnalysisService.analyzeExerciseProgress(
        exerciseId: exerciseId,
        exerciseName: name,
        rawWorkoutSessions: List<Map<String, dynamic>>.from(targetEntry['rawLogs']),
        startDate: _startDate,
        endDate: _endDate,
        targetMuscle: targetEntry['muscle'],
      );

      _analysisData = _analysisData!.copyWith(aiCoachingTip: null);

    } catch (error) {
      debugPrint("Error shifting analytic timeline scopes: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Action trigger hook connected strictly to the manual UI button tap event
  Future<void> triggerManualAiUpdate(String userDisplayName) async {
    if (_analysisData == null) return;

    _isAiLoading = true;
    notifyListeners();

    // 🟢 1. Initialize safe default fallbacks for Flow 1 users
    String goal = "General Strength & Fitness";
    String experience = "Not Specified";
    int age = 25; 
    String gender = "Not Specified";

    // 🟢 2. The On-Demand Fetch Strategy
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          goal = data['fitnessGoal'] ?? goal;
          experience = data['experienceLevel'] ?? experience;
          age = data['age'] ?? age;
          gender = data['gender'] ?? gender;
        }
      }
    } catch (e) {
      debugPrint("Lightweight AI context fetch failed, relying on safe fallbacks: $e");
    }

    // 🟢 3. Hand off the compiled variables to the pipeline
    await runAiCoachingPipeline(
      userDisplayName: userDisplayName,
      age: age,
      gender: gender,
      fitnessGoal: goal,
      experienceLevel: experience,
    );
  }

  /// Connects localized mathematical facts directly into the cloud Generative AI context wrapper
  Future<void> runAiCoachingPipeline({
    required String userDisplayName,
    required int age,
    required String gender,
    required String fitnessGoal,
    required String experienceLevel,
  }) async {
    try {
      final String generatedTipText = await _aiCoachingService.fetchAdaptiveCoachingTip(
        workoutMetrics: _analysisData!,
        userName: userDisplayName,
        age: age,
        gender: gender,
        fitnessGoal: fitnessGoal,
        experienceLevel: experienceLevel,
      );

      _analysisData = _analysisData!.copyWith(aiCoachingTip: generatedTipText);
    } catch (e) {
      debugPrint("AI Coaching framework thread collision: $e");
    } finally {
      _isAiLoading = false;
      notifyListeners();
    }
  }
}