// lib/models/analysis/diet_insight_model.dart

import 'package:flutter/material.dart';

class DietDailyInsightModel {
  final DateTime date;
  
  // Caloric intake boundary variables
  final int loggedCalories;
  final int targetCalories;
  final int calorieVariance;
  final String calorieStatusLabel; // e.g., "Aggressive Window", "Surplus Target"

  // True cellular protein floor recovery variables
  final int loggedProtein;
  final int targetProteinFloor;
  final String proteinStatusLabel; // e.g., "SECURED", "DEFICIT"
  final int proteinDelta;

  // Auxiliary balance rows
  final int loggedCarbs;
  final int loggedFats;

  // Master single-day layout compliance badge tokens
  final String badgeTitle;
  final String badgeExplanation;
  final Color themeColor;
  final IconData statusIconMarker;

  // Personal management summary statement text block
  final String dailyManagementSummary;

  const DietDailyInsightModel({
    required this.date,
    required this.loggedCalories,
    required this.targetCalories,
    required this.calorieVariance,
    required this.calorieStatusLabel,
    required this.loggedProtein,
    required this.targetProteinFloor,
    required this.proteinStatusLabel,
    required this.proteinDelta,
    required this.loggedCarbs,
    required this.loggedFats,
    required this.badgeTitle,
    required this.badgeExplanation,
    required this.themeColor,
    required this.statusIconMarker,
    required this.dailyManagementSummary,
  });
}