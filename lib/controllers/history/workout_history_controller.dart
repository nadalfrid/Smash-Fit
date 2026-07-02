import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';// Ensure correct import
import '../../models/workout_models.dart';
import '../../services/firebase_service.dart';

class WorkoutHistoryController with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool isSaving = false;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedCalendarMonth = DateTime.now();
  DateTime _tempSelectedDate = DateTime.now();
  List<WorkoutLog> _allLogs = [];
  List<WorkoutLog> _filteredLogs = [];
  Set<String> _datesWithWorkouts = {}; 

  StreamSubscription? _historySubscription;
  StreamSubscription? _authSubscription; // 🌟 NEW: Listens for login/logout events

  // --- GETTERS ---
  List<WorkoutLog> get allLogs => _allLogs;
  DateTime get selectedDate => _selectedDate;
  DateTime get focusedCalendarMonth => _focusedCalendarMonth;
  DateTime get tempSelectedDate => _tempSelectedDate;
  List<WorkoutLog> get filteredLogs => _filteredLogs;
  Set<String> get datesWithWorkouts => _datesWithWorkouts;

  WorkoutHistoryController() {
    // 🌟 SMART LIFECYCLE: Controller wakes up automatically when a user logs in!
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _initWorkoutHistoryListener(); // Turn engine ON
      } else {
        clearSession(); // Turn engine OFF securely
      }
    });
  }

  // --- LIFECYCLE MANAGEMENT ---
  void clearSession() {
    _historySubscription?.cancel();
    _allLogs = [];
    _filteredLogs = [];
    _datesWithWorkouts = {};
    notifyListeners();
  }

  // --- DATE FILTER CONTROLS ---
  void updateSelectedDate(DateTime newDate) {
    final now = DateTime.now();
    if (newDate.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59))) return;

    _selectedDate = newDate;
    _filterLogsForSelectedDate();
    notifyListeners();
  }

  // --- BACKGROUND STREAM LISTENERS ---
  void _initWorkoutHistoryListener() {
    _historySubscription?.cancel();
    
    _historySubscription = _firebaseService.getWorkoutsStream().listen(
      (logs) {
        _allLogs = logs;
        
        final Set<String> updatedLoggedDates = {};
        
        for (var log in logs) {
          final date = log.startTime;
          final String dotKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          updatedLoggedDates.add(dotKey);
        }
        
        _datesWithWorkouts = updatedLoggedDates;
        _filterLogsForSelectedDate(); 
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Suppressed workout logs background stream drop payload safely.");
      },
    );
  }

  void _filterLogsForSelectedDate() {
    final String selectedToken = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    _filteredLogs = _allLogs.where((log) {
      final date = log.startTime;
      final String logToken = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      return logToken == selectedToken;
    }).toList();
  }

  void initCalendarPopup() {
    _focusedCalendarMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _tempSelectedDate = _selectedDate;
    notifyListeners();
  }

  void updateFocusedCalendarMonth(int monthOffset) {
    _focusedCalendarMonth = DateTime(_focusedCalendarMonth.year, _focusedCalendarMonth.month + monthOffset, 1);
    notifyListeners();
  }

  void setTempSelectedDate(DateTime date) {
    _tempSelectedDate = date;
    notifyListeners();
  }

  void confirmCalendarSelection() {
    updateSelectedDate(_tempSelectedDate); // This is your existing method that updates the main view
  }

  // --- DATABASE PERSISTENCE CRUD ACTIONS ---
  Future<bool> saveNewWorkout({
    required List<WorkoutExercise> exercises, 
    required DateTime? startTime,
  }) async {
    isSaving = true;
    notifyListeners();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      isSaving = false;
      notifyListeners();
      return false;
    }

    final newLog = WorkoutLog(
      userId: userId,
      startTime: startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      exercises: exercises,
    );

    try {
      await _firebaseService.saveWorkout(newLog);
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWorkout({
    required String logId, 
    required List<WorkoutExercise> exercises, 
    required DateTime? startTime,
    DateTime? endTime,
  }) async {
    isSaving = true;
    notifyListeners();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      isSaving = false;
      notifyListeners();
      return false;
    }

    final updatedLog = WorkoutLog(
      id: logId,
      userId: userId,
      startTime: startTime ?? DateTime.now(),
      // 🟢 FIXED: Now uses the original endTime passed from the view, 
      // preventing the ghost timer from stretching the duration!
      endTime: endTime ?? DateTime.now(), 
      exercises: exercises,
    );

    try {
      await _firebaseService.updateWorkout(updatedLog);
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteWorkout(String id) async {
    try {
      await _firebaseService.deleteWorkout(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // 🌟 NEW: Cleanup auth listener
    _historySubscription?.cancel();
    super.dispose();
  }
}