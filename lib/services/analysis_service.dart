// lib/services/analysis_service.dart

import 'package:flutter/material.dart';
import '../../models/exercise_analysis_model.dart';
import '../../models/diet_model.dart'; 
import '../../models/workout_insight_model.dart'; 
import '../../models/diet_insight_model.dart'; // 🟢 Added to capture Step 1 Single Day models

class AnalysisService {
  /// Calculates the Estimated 1-Rep Max (1RM) using the Epley Equation.
  /// Formula: 1RM = weight * (1 + (reps / 30))
  static double calculateEpley1RM(double weight, int reps) {
    if (reps <= 0) return 0.0;
    if (reps == 1) return weight; 
    return weight * (1 + (reps / 30.0));
  }

  /// 🟢 NEW: Compiles an entire day's workout logs into a cascading list of analyzed exercises and sets.
  /// Runs LiftShift-inspired set-by-set comparison matrices across a full session chronologically.
  static List<ExerciseInsightGroup> compileFullWorkoutInsight(List<dynamic> rawExercisesList) {
    List<ExerciseInsightGroup> exerciseGroups = [];

    for (var exerciseLog in rawExercisesList) {
      final String name = exerciseLog['name'] ?? 'Unknown Movement';
      final List<dynamic> rawSets = exerciseLog['sets'] ?? [];
      
      if (rawSets.isEmpty) continue;

      List<SingleSetAuditLine> analyzedSets = [];
      double accumulatedVolume = 0;

      for (int i = 0; i < rawSets.length; i++) {
        final currentSet = rawSets[i];
        final double currW = (currentSet['weight'] as num? ?? 0.0).toDouble();
        final int currR = currentSet['reps'] as int? ?? 0;

        accumulatedVolume += (currW * currR);

        // Set 1 establishes the session starting point
        if (i == 0) {
          analyzedSets.add(SingleSetAuditLine(
            setNumber: 1,
            badgeTitle: "STARTING LINE",
            explanation: "First working set baseline established. Let's build from here!",
            statusIconMarker: Icons.radio_button_unchecked,
            themeColor: const Color(0xFF94A3B8), // Slate Gray
            weight: currW,
            reps: currR,
          ));
          continue;
        }

        final prevSet = rawSets[i - 1];
        final double prevW = (prevSet['weight'] as num? ?? 0.0).toDouble();
        final int prevR = prevSet['reps'] as int? ?? 0;

        final double dW = currW - prevW;
        final int dR = currR - prevR;

        String badge = "Solid Pace";
        String feedback = "Matched your previous set. Great rhythm and control!";
        IconData icon = Icons.info_outline;
        Color accentColor = const Color(0xFF64748B); // Slate

        // 🧠 LIFTSHIFT SIMPLIFIED DELTA ENGINE MATRIX 
        // Branch A: Kept the weight completely flat (dW == 0)
        if (dW == 0) {
          if (dR > 0) {
            badge = "Pushing Limits";
            feedback = "Same weight but squeezed out extra reps. Strong adaptation!";
            icon = Icons.arrow_upward;
            accentColor = const Color(0xFF16A34A); // Vibrant Green
          } else if (dR == 0) {
            badge = "Solid Pace";
            feedback = "Matched your previous set perfectly. Great execution!";
            icon = Icons.info_outline;
            accentColor = const Color(0xFF64748B); // Slate
          } else if (dR >= -2 && dR < 0) {
            badge = "Normal Fatigue";
            feedback = "Lost a rep or two. Completely normal muscle energy depletion.";
            icon = Icons.info_outline;
            accentColor = const Color(0xFF64748B); // Slate
          } else {
            badge = "Sudden Drop";
            feedback = "Sharp loss of reps. Your muscles are exhausted. Rest longer next set.";
            icon = Icons.warning_amber_rounded;
            accentColor = const Color(0xFFEA580C); // Orange
          }
        } 
        // Branch B: Increased the weight load (dW > 0)
        else if (dW > 0) {
          if (dR >= 0) {
            badge = "Crushed It";
            feedback = "Added weight AND matched or beat your reps. Amazing strength leap!";
            icon = Icons.star_rounded;
            accentColor = const Color(0xFFD97706); // Amber Gold
          } else if (dR == -1) {
            badge = "Step Up";
            feedback = "Stepped up to a heavier weight while maintaining your target reps.";
            icon = Icons.star_rounded;
            accentColor = const Color(0xFF1E9E88); // Smash Fit Teal
          } else {
            badge = "Too Heavy";
            feedback = "The weight jump cut your reps down too early. Keep it a bit lighter.";
            icon = Icons.trending_down;
            accentColor = const Color(0xFFDC2626); // Red
          }
        } 
        // Branch C: Decreased the weight load strategically (dW < 0)
        else {
          if (dR >= 0) {
            badge = "Smart Drop-Off";
            feedback = "Dropped weight intentionally to keep rep count high. Perfect volume build.";
            icon = Icons.build_circle_outlined;
            accentColor = const Color(0xFF0D9488); // Deep Teal
          } else {
            badge = "Heavy Drop";
            feedback = "Dropped weight but still lost reps. Fatigue has fully set in.";
            icon = Icons.trending_down;
            accentColor = const Color(0xFFDC2626); // Red
          }
        }

        analyzedSets.add(SingleSetAuditLine(
          setNumber: i + 1,
          badgeTitle: badge,
          explanation: feedback,
          statusIconMarker: icon,
          themeColor: accentColor,
          weight: currW,
          reps: currR,
        ));
      }

      // Synthesize customized bottom card summary feedback critique strings
      String summaryCritique = "Workout volume looking healthy. Keep nailing this weight setup.";
      final bool hasOverreached = analyzedSets.any((s) => s.badgeTitle == "Too Heavy");
      final bool hasCrushedIt = analyzedSets.any((s) => s.badgeTitle == "Crushed It" || s.badgeTitle == "Pushing Limits");
      final bool hasSpikes = analyzedSets.any((s) => s.badgeTitle == "Sudden Drop" || s.badgeTitle == "Heavy Drop");

      if (hasOverreached) {
        summaryCritique = "The weight increases cut your performance short today. Next workout, try using smaller weight adjustments.";
      } else if (hasCrushedIt && !hasSpikes) {
        summaryCritique = "Outstanding performance! You successfully beat your targets. Consider safely leveling up your starting weight next week.";
      } else if (hasSpikes) {
        summaryCritique = "Your strength dropped off quickly between sets. Try adding 45 to 60 seconds of extra rest between sets to fully recover.";
      }

      exerciseGroups.add(ExerciseInsightGroup(
        exerciseName: name,
        totalExerciseVolume: double.parse(accumulatedVolume.toStringAsFixed(1)),
        volumeFeedbackString: summaryCritique,
        analyzedSets: analyzedSets,
      ));
    }

    return exerciseGroups;
  }

  /// Takes raw workout data, applies a date filter window, computes 1RM trends,
  /// and determines the LiftShift-inspired progress status based on partitioning averages.
  static ExerciseAnalysisModel analyzeExerciseProgress({
    required String exerciseId,
    required String exerciseName,
    required List<Map<String, dynamic>> rawWorkoutSessions, 
    required DateTime startDate,
    required DateTime endDate,
    required String targetMuscle, 
  }) {
    // 1. Filter and sort logs within the selected calendar date range
    final filteredSessions = rawWorkoutSessions.where((session) {
      final DateTime date = session['workoutDate'];
      return date.isAfter(startDate.subtract(const Duration(days: 1))) && 
             date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Sort oldest to newest
    filteredSessions.sort((a, b) => (a['workoutDate'] as DateTime).compareTo(b['workoutDate'] as DateTime));

    // 2. Extract metrics variables
    List<DateTime> finalDates = [];
    List<double> estimated1RMs = [];
    double globalBestWeight = 0.0;
    int totalSets = 0;
    int totalReps = 0;

    for (var session in filteredSessions) {
      final DateTime date = session['workoutDate'];
      final List<Map<String, dynamic>> sets = List<Map<String, dynamic>>.from(session['sets']);
      
      double sessionMax1RM = 0.0;

      for (var set in sets) {
        final double weight = (set['weight'] as num).toDouble();
        final int reps = set['reps'] as int;

        totalSets++;
        totalReps += reps;
        if (weight > globalBestWeight) globalBestWeight = weight;

        double currentSet1RM = calculateEpley1RM(weight, reps);
        if (currentSet1RM > sessionMax1RM) {
          sessionMax1RM = currentSet1RM;
        }
      }

      if (sessionMax1RM > 0) {
        finalDates.add(date);
        estimated1RMs.add(double.parse(sessionMax1RM.toStringAsFixed(1)));
      }
    }

    int sessionsCount = estimated1RMs.length;
    double avgReps = totalSets > 0 ? (totalReps / totalSets) : 0.0;

    // 🌟 GATING FOR NEW EXERCISE / CALIBRATION MODE
    if (sessionsCount < 3) {
      return ExerciseAnalysisModel(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        targetMuscle: targetMuscle, 
        workoutDates: finalDates,
        estimatedOneRepMaxHistory: estimated1RMs,
        bestWeightLIFTED: globalBestWeight,
        totalSetsLogged: totalSets,
        totalSessionsCount: sessionsCount,
        averageRepsPerSet: double.parse(avgReps.toStringAsFixed(1)),
        statusLabel: "new", 
        confidenceLevel: "Calibrating",
        progressPercentage: 0.0,
      );
    }

    // 4. Determine LiftShift Status & Progress Percentages for calibrated exercises via Window Partitioning
    String statusLabel = "plateauing";
    String confidenceLevel = "Low Confidence";
    double progressPct = 0.0;

    if (sessionsCount >= 10) {
      confidenceLevel = "High Confidence";
    } else if (sessionsCount >= 6) {
      confidenceLevel = "Medium Confidence";
    }

    // Dynamic Window Partitioning: Compare recent sessions to previous sessions half boundaries
    int halfLength = (sessionsCount / 2).floor();
    
    List<double> pastWindow = estimated1RMs.sublist(0, halfLength);
    List<double> recentWindow = estimated1RMs.sublist(sessionsCount - halfLength);

    double pastAvg = pastWindow.reduce((a, b) => a + b) / pastWindow.length;
    double recentAvg = recentWindow.reduce((a, b) => a + b) / recentWindow.length;

    progressPct = double.parse((((recentAvg - pastAvg) / pastAvg) * 100).toStringAsFixed(1));

    if (progressPct > 1.0) {
      statusLabel = "gaining";
    } else if (progressPct < -3.0) {
      statusLabel = "losing"; 
    } else {
      statusLabel = "plateauing";
    }

    return ExerciseAnalysisModel(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      targetMuscle: targetMuscle, 
      workoutDates: finalDates,
      estimatedOneRepMaxHistory: estimated1RMs,
      bestWeightLIFTED: globalBestWeight,
      totalSetsLogged: totalSets,
      totalSessionsCount: sessionsCount,
      averageRepsPerSet: double.parse(avgReps.toStringAsFixed(1)),
      statusLabel: statusLabel,
      confidenceLevel: confidenceLevel,
      progressPercentage: progressPct,
    );
  }

  // ==========================================================================
  // 🌟 ENHANCED: UNIFIED NUTRISHIFT DUAL LAYER ANALYSIS ENGINE
  // ==========================================================================

  /// Analyzes raw diet collections, processing both macro timeline trend phrases 
  /// and granular micro-compliance calendar histories simultaneously.
  static Map<String, dynamic> analyzeDietMacroTrend({
    required List<FoodItem> rawFoodItems,
    required int dailyCalorieTarget,
    required int targetProteinFloor, 
  }) {
    if (rawFoodItems.isEmpty) {
      return {
        'status': 'No Data',
        'averageDailyCalories': 0,
        'averageDailyProtein': 0,
        'daysLoggedCount': 0,
        'dailyLogs': <DailyDietLog>[],
        'microComplianceHistory': <Map<String, dynamic>>[],
      };
    }

    // 1. Cluster individual logged foods into unique YYYY-MM-DD date index buckets
    final Map<String, List<FoodItem>> groupedByDate = {};
    
    for (var item in rawFoodItems) {
      final DateTime t = item.timestamp;
      final String dateKey = "${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}";
      groupedByDate.putIfAbsent(dateKey, () => []);
      groupedByDate[dateKey]!.add(item);
    }

    // 2. Wrap calendar maps into summary objects and parse tracking totals
    final List<DailyDietLog> dailyLogs = [];
    final List<Map<String, dynamic>> dailyComplianceList = []; 
    int totalWindowCalories = 0;
    int totalWindowProtein = 0;

    groupedByDate.forEach((dateString, itemsList) {
      final parts = dateString.split('-');
      final logDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      
      final dayLog = DailyDietLog(date: logDate, items: itemsList);
      dailyLogs.add(dayLog);

      // 3. GRANULAR MICRO-COMPLIANCE CALCULATION PASS (Day-by-Day)
      String microStatusLabel = "Balanced Maintenance Intake";
      final int calorieDifference = dayLog.totalCalories - dailyCalorieTarget;

      if (calorieDifference < -400 && dayLog.totalProtein >= targetProteinFloor) {
        microStatusLabel = "Energy Deflation Window";
      } else if (calorieDifference < -500 && dayLog.totalProtein < (targetProteinFloor - 30)) {
        microStatusLabel = "Catabolic Muscle Hazard";
      } else if (calorieDifference.abs() <= (dailyCalorieTarget * 0.15) && dayLog.totalProtein >= (targetProteinFloor - 15)) {
        microStatusLabel = "Optimal Recovery Fueling";
      } else if (calorieDifference > 200) {
        microStatusLabel = "Caloric Surplus Overflow";
      }

      dailyComplianceList.add({
        'date': logDate,
        'totalCalories': dayLog.totalCalories,
        'totalProtein': dayLog.totalProtein,
        'microStatus': microStatusLabel,
      });

      totalWindowCalories += dayLog.totalCalories;
      totalWindowProtein += dayLog.totalProtein;
    });

    // Chronological rendering alignment
    dailyLogs.sort((a, b) => a.date.compareTo(b.date));
    dailyComplianceList.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // 4. Compute overall macro average parameters
    final int daysCount = dailyLogs.length;
    final int avgDailyCalories = (totalWindowCalories / daysCount).round();
    final int avgDailyProtein = (totalWindowProtein / daysCount).round();

    // 5. Map boundaries to target profile TDEE ranges for long-term trends
    String macroStatus = 'Holding Steady';
    final int globalCalorieDifference = avgDailyCalories - dailyCalorieTarget;

    if (globalCalorieDifference < -200) {
      macroStatus = 'Consistent Deficit'; 
    } else if (globalCalorieDifference > 200) {
      macroStatus = 'Consistent Surplus'; 
    } else {
      macroStatus = 'Holding Steady';
    }

    // Volatility checker
    if (daysCount >= 3) {
      double varianceSum = 0;
      for (var log in dailyLogs) {
        varianceSum += (log.totalCalories - avgDailyCalories).abs();
      }
      final double averageDeviation = varianceSum / daysCount;
      
      if (averageDeviation > 600) {
        macroStatus = 'Unstable Intake';
      }
    }

    return {
      'status': macroStatus,
      'averageDailyCalories': avgDailyCalories,
      'averageDailyProtein': avgDailyProtein,
      'daysLoggedCount': daysCount,
      'dailyLogs': dailyLogs,
      'microComplianceHistory': dailyComplianceList, 
    };
  }

// ==========================================================================
  // 🌟 ENHANCED: SINGLE-DAY GRANULAR NUTRISHIFT MICRO TIMELINE COMPLIANCE ENGINE
  // ==========================================================================

  static DietDailyInsightModel compileDailyDietInsight({
    required DateTime selectedDate,
    required List<FoodItem> rawDayFoods,
    required int dailyCalorieTarget,
    required int targetProteinFloor,
  }) {
    // 1. Sum individual item nutrients
    int totalCal = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFats = 0;

    for (var food in rawDayFoods) {
      totalCal += food.calories;
      totalProtein += food.protein;
      totalCarbs += food.carbs;
      totalFats += food.fat;
    }

    final int calorieVariance = totalCal - dailyCalorieTarget;
    final int proteinDelta = totalProtein - targetProteinFloor;

    // 2. Establish Time Context
    final DateTime now = DateTime.now();
    final bool isToday = selectedDate.year == now.year && 
                         selectedDate.month == now.month && 
                         selectedDate.day == now.day;
                         
    // Strip time for accurate past-day comparison
    final DateTime todayMidnight = DateTime(now.year, now.month, now.day);
    final DateTime targetMidnight = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final bool isPast = targetMidnight.isBefore(todayMidnight);

    // Default variable initialization
    String badgeTitle;
    String explanation;
    Color themeColor;
    IconData iconMarker;
    String calorieStatusLabel;
    String proteinStatusLabel;
    String managementSummary;

    // 🧠 NUTRISHIFT BOUNDARY MATRIX VERIFICATION ENGINE

    // 🌟 NEW STATE 1: Past Date with NO FOOD logged
    if (isPast && rawDayFoods.isEmpty) {
      badgeTitle = "NO DATA LOGGED";
      explanation = "No dietary intakes were recorded on this date. Nutritional analysis cannot be performed.";
      themeColor = const Color(0xFF94A3B8); // Cool Neutral Slate
      iconMarker = Icons.event_busy_outlined;
      calorieStatusLabel = "Unrecorded";
      proteinStatusLabel = "UNRECORDED";
      managementSummary = "No nutritional data was tracked for this day. Consistency is key—try to log at least your major meals to keep your historical trend data accurate and actionable.";
    }
    // 🌟 NEW STATE 2: Current Active Day (Ongoing Analysis)
    else if (isToday) {
      badgeTitle = "ANALYSIS ONGOING";
      explanation = "Your day is currently active. Keep logging your meals. Final metabolic compliance will calculate at midnight.";
      themeColor = const Color(0xFF3B82F6); // Active Tracker Blue
      iconMarker = Icons.timelapse_rounded;
      calorieStatusLabel = "Tracking in Progress";
      proteinStatusLabel = "TRACKING";
      managementSummary = "Your daily log is open and active. Keep fueling up and logging your intakes. Your final metabolic execution analysis will lock in at the end of the day.";
    }
    // 🧠 ORIGINAL STATES: Past Date WITH Food (Normal Matrix)
    else {
      // SCENARIO 3: Catabolic Muscle Hazard Check
      if (calorieVariance < -500 && proteinDelta < -30) {
        badgeTitle = "CATABOLIC MUSCLE HAZARD";
        explanation = "Critical recovery alert! Your calories and protein are both dangerously low. Your body risks breaking down muscle tissue for energy.";
        themeColor = const Color(0xFFDC2626); // Alert Crimson Red
        iconMarker = Icons.gavel_rounded;
        calorieStatusLabel = "Critical Deficit Window";
        proteinStatusLabel = "DANGEROUS DEFICIT";
        managementSummary = "Critical recovery shortfall caught. Severe under-fueling combined with an amino acid deficit threatens active lean muscle retention. Prioritize hitting your target protein floor tomorrow.";
      }
      // SCENARIO 2: Energy Deflation Window Check 
      else if (calorieVariance < -400 && proteinDelta >= 0) {
        badgeTitle = "ENERGY DEFLATION WINDOW";
        explanation = "Safe fat-loss state. You are in a clean calorie deficit for fat burning, while your high protein intake safely protects your lean muscle tissue.";
        themeColor = const Color(0xFFEA580C); // Energetic Burn Orange
        iconMarker = Icons.local_fire_department_outlined;
        calorieStatusLabel = "Aggressive Deficit Window";
        proteinStatusLabel = "SECURED";
        managementSummary = "Aggressive calorie deficit handled beautifully. Your protein intake safely shielded your lean tissue mass from catabolic breakdown today. Excellent fat loss trajectory.";
      }
      // SCENARIO 4: Caloric Surplus Overflow Check 
      else if (calorieVariance > 200) {
        badgeTitle = "CALORIC SURPLUS OVERFLOW";
        explanation = "Bulking window. You are consuming extra energy, which is ideal for building mass. Keep an eye on consistency if your main goal is fat loss.";
        themeColor = const Color(0xFF0D9488); // Structural Teal
        iconMarker = Icons.add_chart_rounded;
        calorieStatusLabel = "Surplus Target Window";
        proteinStatusLabel = proteinDelta >= 0 ? "SECURED" : "DEFICIT";
        managementSummary = "In a caloric surplus window. This environment is ideal for adding clean structural weight or strength phases, but monitor consistency closely if your current goal shifts toward fat loss.";
      }
      // SCENARIO 1: Optimal Recovery Fueling Check 
      else {
        final double variancePercentage = (calorieVariance.abs() / dailyCalorieTarget);
        if (variancePercentage <= 0.15 && proteinDelta >= 0) {
          badgeTitle = "OPTIMAL RECOVERY FUELING";
          explanation = "Perfect execution! Your calorie intake matches your energy needs, and you hit your protein target to support muscle recovery and growth.";
          themeColor = const Color(0xFF16A34A); // Green
          iconMarker = Icons.check_circle_outline;
          calorieStatusLabel = "Balanced Ingestion Range";
          proteinStatusLabel = "SECURED";
          managementSummary = "Perfect alignment achieved today. Caloric delivery closely matched your metabolic output while premium protein availability successfully protected lean tissue recovery structures.";
        } else {
          badgeTitle = "INCOMPLETE RECOVERY FUEL";
          explanation = "Calories look good, but protein targets fell short. Increase amino availability to fully back up your recovery goals.";
          themeColor = const Color(0xFF64748B); // Cool Neutral Slate
          iconMarker = Icons.info_outline;
          calorieStatusLabel = "Maintenance Range";
          proteinStatusLabel = "DEFICIT";
          managementSummary = "Caloric intake levels landed within a safe maintenance window, but your muscle recovery pool remains limited due to missing the protein floor. Focus on lean meats or shakes next pass.";
        }
      }
    }

    return DietDailyInsightModel(
      date: selectedDate,
      loggedCalories: totalCal,
      targetCalories: dailyCalorieTarget,
      calorieVariance: calorieVariance,
      calorieStatusLabel: calorieStatusLabel,
      loggedProtein: totalProtein,
      targetProteinFloor: targetProteinFloor,
      proteinStatusLabel: proteinStatusLabel,
      proteinDelta: proteinDelta,
      loggedCarbs: totalCarbs,
      loggedFats: totalFats,
      badgeTitle: badgeTitle,
      badgeExplanation: explanation,
      themeColor: themeColor,
      statusIconMarker: iconMarker,
      dailyManagementSummary: managementSummary,
    );
  }
}