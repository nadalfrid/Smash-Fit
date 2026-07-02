// lib/models/analysis/workout_insight_model.dart

import 'package:flutter/material.dart';

class WorkoutInsightModel {
  final String workoutTitle;
  final DateTime workoutDate;
  final List<ExerciseInsightGroup> exercisesData;

  WorkoutInsightModel({
    required this.workoutTitle,
    required this.workoutDate,
    required this.exercisesData,
  });
}

class ExerciseInsightGroup {
  final String exerciseName;
  final double totalExerciseVolume;
  final String volumeFeedbackString;
  final List<SingleSetAuditLine> analyzedSets;

  ExerciseInsightGroup({
    required this.exerciseName,
    required this.totalExerciseVolume,
    required this.volumeFeedbackString,
    required this.analyzedSets,
  });
}

class SingleSetAuditLine {
  final int setNumber;
  final String badgeTitle;
  final String explanation;
  final IconData statusIconMarker; 
  final Color themeColor;       
  final double weight;
  final int reps;

  SingleSetAuditLine({
    required this.setNumber,
    required this.badgeTitle,
    required this.explanation,
    required this.statusIconMarker,
    required this.themeColor,
    required this.weight,
    required this.reps,
  });
}