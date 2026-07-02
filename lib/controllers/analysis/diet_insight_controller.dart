import 'package:flutter/material.dart';
import '../../models/diet_insight_model.dart';
import '../../models/diet_model.dart'; 
import '../../services/analysis_service.dart';
import '../../services/ai_coaching_service.dart'; // 🌟 Added AI Service

class DietInsightController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<DateTime> _calendarStripDays = [];
  DietDailyInsightModel? _currentDayInsight;
  List<FoodItem> _currentDayFoods = []; // 🌟 Remembers today's foods for the AI

  // 🌟 AI State Variables
  bool _isAiLoading = false;
  String? _dailyAiInsightText;
  final AICoachingService _aiService = AICoachingService();

  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  List<DateTime> get calendarStripDays => _calendarStripDays;
  DietDailyInsightModel? get currentDayInsight => _currentDayInsight;
  bool get isAiLoading => _isAiLoading;
  String? get dailyAiInsightText => _dailyAiInsightText;

  DietInsightController() {
    _generateCalendarStrip();
  }

  void _generateCalendarStrip() {
    final List<DateTime> steps = [];
    for (int i = -3; i <= 3; i++) {
      steps.add(_selectedDate.add(Duration(days: i)));
    }
    _calendarStripDays = steps;
  }

  Future<void> selectActiveDate(DateTime targetDate, dynamic sharedDietController) async {
    if (DateUtils.isSameDay(_selectedDate, targetDate) && _currentDayInsight != null) return;

    _isLoading = true;
    _selectedDate = targetDate;
    _dailyAiInsightText = null; // 🌟 Clear the AI text when changing days!
    _generateCalendarStrip(); 
    notifyListeners();

    sharedDietController.updateHistoryDate(targetDate);

    try {
      final DateTime startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
      final DateTime endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
      final List<FoodItem> directDayFoods = await sharedDietController.getDietLogsInWindow(startOfDay, endOfDay);

      recalculateDailyNutritionInsight(sharedDietController, directFoods: directDayFoods);
    } catch (error) {
      debugPrint("🎯 Error fetching direct date logs: $error");
      _isLoading = false;
      notifyListeners();
    }
  }

  void recalculateDailyNutritionInsight(dynamic sharedDietController, {List<FoodItem>? directFoods}) {
    _isLoading = true;
    notifyListeners();

    try {
      if (directFoods != null) {
        _currentDayFoods = directFoods;
      } else {
        _currentDayFoods = [];
        final List<MealCategory> structuralMeals = sharedDietController.historyMeals ?? [];
        for (var category in structuralMeals) {
          _currentDayFoods.addAll(category.items);
        }
      }

      final int activeTDEEBaseline = sharedDietController.targetCalories;
      final int activeProteinFloor = sharedDietController.maxProtein;

      _currentDayInsight = AnalysisService.compileDailyDietInsight(
        selectedDate: _selectedDate,
        rawDayFoods: _currentDayFoods,
        dailyCalorieTarget: activeTDEEBaseline,
        targetProteinFloor: activeProteinFloor,
      );
    } catch (error) {
      debugPrint("🎯 Error processing nutrition insights: $error");
      _currentDayInsight = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🌟 NEW: The function that fires when the user taps the generate button
  Future<void> generateDailyAiInsight(dynamic sharedDietController) async {
    if (_currentDayInsight == null) return;

    _isAiLoading = true;
    notifyListeners();

    // Extract just the names of the foods eaten
    List<String> foodNames = _currentDayFoods.map((f) => f.name).toList();
    String userName = sharedDietController.userProfile?.name ?? "Faozan";

    _dailyAiInsightText = await _aiService.fetchDailyFoodQualityInsight(
      userName: userName,
      date: _selectedDate,
      calorieVariance: _currentDayInsight!.calorieVariance,
      proteinDelta: _currentDayInsight!.proteinDelta,
      foodNamesLogged: foodNames,
    );

    _isAiLoading = false;
    notifyListeners();
  }
}