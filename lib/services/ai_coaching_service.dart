import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/exercise_analysis_model.dart';

class AICoachingService {
  // Replace this placeholder string with your real API key copied from Google AI Studio
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  late final GenerativeModel _model;
  late final GenerativeModel _nutritionModel;
  late final GenerativeModel _dailyNutritionModel;

  AICoachingService() {
    // ---------------------------------------------------------
    // 🏋️ EXERCISE MECHANICS MODEL (Unchanged)
    // ---------------------------------------------------------
    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        "You are the expert Strength and Conditioning Coach integrated inside the 'Smash Fit' mobile app. "
        "Your task is to analyze an exercise's performance data alongside the user's personal biometrics and goals. "
        "Instead of relying on rigid progression rules, act like a veteran coach: scan the data to find the primary narrative or anomaly "
        "(e.g., sudden drop in reps indicating stamina issues, consistent weight increases showing perfect overload, or a plateau). "
        "Prescribe a specific, actionable mechanical adjustment grounded strictly in their listed experience level and fitness goal. "
        "CRITICAL RULES: "
        "1. Express all weight alterations strictly in kilograms (kg) units (e.g., 'increase by 2.5kg' or 'drop by 5kg'). "
        "2. Never use percentages (%) to describe adding or reducing weight. "
        "3. Do NOT mention calories, macros, or food under any circumstance. "
        "4. Address the user directly by name. Limit your response to a tight, punchy paragraph of exactly 3 to 4 sentences maximum to fit the UI constraints. "
        "5. Use simple, direct coaching terms. Do not use prefatory phrases describing their data back to them."
      ),
    );

    // ---------------------------------------------------------
    // 🥗 NUTRITIONAL DIAGNOSTIC MODEL (New & Mathematically Brutal)
    // ---------------------------------------------------------
    _nutritionModel = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        "You are the elite, highly analytical Sports Nutritionist AI integrated inside the 'Smash Fit' mobile app. "
        "Your task is to analyze the user's multi-day dietary macro trends against their current body weight and target weight. "
        "You MUST base your primary critique on their 'rolling_status_label' (e.g., 'Consistent Deficit', 'Consistent Surplus', 'Unstable Intake'). "
        "Tell the user bluntly and honestly if their eating habits and current macro averages are mathematically ruining or supporting their trajectory toward their target weight. "
        "Use their exact protein and calorie numbers to prove your point. Prescribe a precise, actionable metabolic adjustment to fix or maintain their current phase. "
        "CRITICAL RULES: "
        "1. Do NOT provide generic advice. Give hard, diagnostic truths based strictly on the mathematical data provided. "
        "2. Limit your response to a punchy paragraph of exactly 3 to 4 sentences to fit UI constraints. "
        "3. Address the user directly by name. "
        "4. Do not use prefatory phrases describing their data back to them."
      ),
    );

    // ---------------------------------------------------------
    // 🎯 DAILY TACTICAL NUTRITION MODEL (Single Day Focus)
    // ---------------------------------------------------------
    _dailyNutritionModel = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        "You are the tactical daily Nutritionist AI inside the 'Smash Fit' app. "
        "Your task is to analyze a SINGLE 24-hour window of logged food. "
        "Look at the specific names of the foods the user ate and the resulting macro variances. "
        "Call out exactly which foods helped them or hurt them today. "
        "CRITICAL RULES: "
        "1. Do not give generic advice. Point directly to the food items they logged (e.g., 'Your Nasi Lemak spiked carbs...'). "
        "2. Limit response to exactly 3 to 4 punchy sentences. "
        "3. Address the user directly by name. "
        "4. Prescribe a specific food to eat tomorrow to fix any deficits."
      ),
    );
  }

  /// 🟢 Existing: Injects the user's biometric state alongside the isolated workout metrics
  Future<String> fetchAdaptiveCoachingTip({
    required ExerciseAnalysisModel workoutMetrics,
    required String userName,
    required int age,
    required String gender,
    required String fitnessGoal,
    required String experienceLevel,
  }) async {
    try {
      final Map<String, dynamic> mechanicsProfileData = {
        'user_biometrics_and_goals': {
          'user_display_name': userName,
          'age': age,
          'gender': gender,
          'fitness_goal': fitnessGoal,
          'experience_level': experienceLevel,
        },
        'exercise_mechanics': {
          'exercise_name': workoutMetrics.exerciseName,
          'target_muscle': workoutMetrics.targetMuscle,
          'current_status_label': workoutMetrics.statusLabel,
          'strength_variance_percentage': workoutMetrics.progressPercentage,
          'metrics_window': {
            'best_weight_lifted': workoutMetrics.bestWeightLIFTED,
            'total_sets_logged': workoutMetrics.totalSetsLogged,
            'total_sessions_count': workoutMetrics.totalSessionsCount,
            'average_reps_per_set': workoutMetrics.averageRepsPerSet,
          }
        }
      };

      final String jsonPayloadText = const JsonEncoder.withIndent('  ').convert(mechanicsProfileData);
      final promptText = "Analyze this exercise training matrix packet and deliver a 3-to-4 sentence actionable strategy:\n$jsonPayloadText";

      final response = await _model.generateContent([Content.text(promptText)]);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      }
      return "Keep executing clean movement patterns. Track your upcoming sessions to refine your volume load progression line.";
    } catch (e) {
      debugPrint("Error connecting to Gemini Cloud Engine: $e");
      return "Unable to load dynamic coach insights right now. Keep pushing hard toward your fitness goals!";
    }
  }

  /// 🌟 NEW: The Bulletproof, Numbers-Only Nutrition Payload
  Future<String> fetchAdaptiveNutritionStrategy({
    required String statusLabel,
    required int avgDailyCalories,
    required int targetCalories,
    required int avgDailyProtein,
    required int targetProtein,
    required int daysAnalyzed,
    required String userName,
    required int age,
    required String gender,
    required double currentWeight,
    required double? targetWeight,
  }) async {
    try {
      final Map<String, dynamic> nutritionalProfileData = {
        'biological_profile': {
          'user_display_name': userName,
          'age': age,
          'gender': gender,
          'current_weight_kg': currentWeight,
          'target_weight_kg': targetWeight,
        },
        '7_day_macro_trends': {
          'rolling_status_label': statusLabel,
          'average_daily_calories_logged': avgDailyCalories,
          'target_daily_calories': targetCalories,
          'average_daily_protein_logged': avgDailyProtein,
          'target_daily_protein': targetProtein,
          'total_days_analyzed': daysAnalyzed,
        }
      };

      final String jsonPayloadText = const JsonEncoder.withIndent('  ').convert(nutritionalProfileData);
      final promptText = "Analyze this macro dietary trend packet and deliver a 3-to-4 sentence actionable metabolic strategy:\n$jsonPayloadText";

      final response = await _nutritionModel.generateContent([Content.text(promptText)]);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      }
      return "Maintain your current fueling parameters. Continue tracking your daily intake to establish a clearer metabolic baseline.";
    } catch (e) {
      debugPrint("Error connecting to Gemini Cloud Engine (Nutrition): $e");
      return "Unable to load dynamic nutritional insights right now. Keep hitting your macro targets!";
    }
  }

  Future<String> fetchDailyFoodQualityInsight({
    required String userName,
    required DateTime date,
    required int calorieVariance,
    required int proteinDelta,
    required List<String> foodNamesLogged,
  }) async {
    try {
      final Map<String, dynamic> dailyData = {
        'user_name': userName,
        'date': date.toIso8601String(),
        'calorie_variance_from_target': calorieVariance,
        'protein_variance_from_target': proteinDelta,
        'specific_foods_eaten_today': foodNamesLogged.isEmpty ? ["No food logged"] : foodNamesLogged,
      };

      final String jsonPayload = const JsonEncoder.withIndent('  ').convert(dailyData);
      final promptText = "Analyze today's specific food logs and variances. Deliver a 3-sentence tactical critique:\n$jsonPayload";

      final response = await _dailyNutritionModel.generateContent([Content.text(promptText)]);
      
      return response.text?.trim() ?? "Your daily logs are recorded. Keep focusing on whole foods and hitting your protein targets!";
    } catch (e) {
      debugPrint("Error connecting to Gemini Daily Coach: $e");
      return "Unable to load dynamic daily insights right now. Keep hitting your macro targets!";
    }
  }
}