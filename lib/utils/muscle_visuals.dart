// lib/utils/muscle_visuals.dart
import 'package:flutter/material.dart';

class MuscleVisuals {
  final Color backgroundColor;
  final Color textColor;
  final String imagePath;

  MuscleVisuals({
    required this.backgroundColor,
    required this.textColor,
    required this.imagePath,
  });

  static MuscleVisuals getVisuals(String targetMuscle) {
    // Clean the string to match your exact API list
    final target = targetMuscle.trim().toLowerCase();

    switch (target) {
      // ==========================================
      // CHEST & SHOULDERS (Blues / Indigos)
      // ==========================================
      case 'pectorals':
      case 'chest': 
        return MuscleVisuals(
            backgroundColor: Colors.blue.shade50, textColor: Colors.blue.shade700, imagePath: 'assets/icons/pectorals.png');
      
      case 'delts':
      case 'deltoids':
      case 'shoulder': // 🟢 FIXED: Catches generic plan variations for shoulder days
      case 'shoulders':
        return MuscleVisuals(
            backgroundColor: Colors.indigo.shade50, textColor: Colors.indigo.shade700, imagePath: 'assets/icons/delts.png');
      
      // ==========================================
      // BACK (Purples)
      // ==========================================
      case 'lats':
      case 'back': // 🟢 FIXED: Automatically links raw parent 'back' strings to your lats visual asset
        return MuscleVisuals(
            backgroundColor: Colors.purple.shade50, textColor: Colors.purple.shade700, imagePath: 'assets/icons/lats.png');
      case 'upper back':
        return MuscleVisuals(
            backgroundColor: Colors.deepPurple.shade50, textColor: Colors.deepPurple.shade700, imagePath: 'assets/icons/upper back.png');
      case 'traps':
        return MuscleVisuals(
            backgroundColor: Colors.purple.shade50, textColor: Colors.purple.shade700, imagePath: 'assets/icons/traps.png');
      case 'spine':
        return MuscleVisuals(
            backgroundColor: Colors.deepPurple.shade50, textColor: Colors.deepPurple.shade700, imagePath: 'assets/icons/spine.png');
      case 'levator scapulae':
        return MuscleVisuals(
            backgroundColor: Colors.purple.shade50, textColor: Colors.purple.shade700, imagePath: 'assets/icons/levator scapulae.png');

      // ==========================================
      // ARMS (Reds / Pinks)
      // ==========================================
      case 'biceps':
      case 'bicep': // 🟢 FIXED: Protects against singular/plural typing mismatches
        return MuscleVisuals(
            backgroundColor: Colors.red.shade50, textColor: Colors.red.shade700, imagePath: 'assets/icons/biceps.png');
      case 'triceps':
      case 'tricep': // 🟢 FIXED: Protects against singular/plural typing mismatches
        return MuscleVisuals(
            backgroundColor: Colors.pink.shade50, textColor: Colors.pink.shade700, imagePath: 'assets/icons/triceps.png');
      case 'forearms':
        return MuscleVisuals(
            backgroundColor: Colors.redAccent.shade100.withOpacity(0.2), textColor: Colors.red.shade800, imagePath: 'assets/icons/forearms.png');

      // ==========================================
      // CORE (Greens)
      // ==========================================
      case 'waist':
      case 'abs':
        return MuscleVisuals(
            backgroundColor: Colors.green.shade50, textColor: Colors.green.shade700, imagePath: 'assets/icons/abs.png');

      // ==========================================
      // LEGS (Oranges / Teals)
      // ==========================================
      case 'quads':
      case 'upper legs': // 🟢 FIXED: Automatically handles leg-day template arrays seamlessly
        return MuscleVisuals(
            backgroundColor: Colors.teal.shade50, textColor: Colors.teal.shade700, imagePath: 'assets/icons/quads.png');
      case 'hamstrings':
      case 'posterior': // 🟢 FIXED: Map hyperextension tracking nodes safely
        return MuscleVisuals(
            backgroundColor: Colors.orange.shade50, textColor: Colors.orange.shade700, imagePath: 'assets/icons/hamstrings.png');
      case 'glutes':
        return MuscleVisuals(
            backgroundColor: Colors.deepOrange.shade50, textColor: Colors.deepOrange.shade700, imagePath: 'assets/icons/glutes.png');
      
      case 'calves':
      case 'calf': // 🟢 FIXED: Map standing calf raise strings completely
      case 'lower legs':
        return MuscleVisuals(
            backgroundColor: Colors.cyan.shade50, textColor: Colors.cyan.shade700, imagePath: 'assets/icons/calves.png');
      
      case 'abductors':
      case 'abductor':
        return MuscleVisuals(
            backgroundColor: Colors.amber.shade50, textColor: Colors.amber.shade800, imagePath: 'assets/icons/abductors.png');
      
      case 'adductors':
      case 'adductor': // 🟢 FIXED: Map hip adduction categories cleanly
        return MuscleVisuals(
            backgroundColor: Colors.orangeAccent.shade100.withOpacity(0.2), textColor: Colors.orange.shade900, imagePath: 'assets/icons/adductors.png');

      // ==========================================
      // MISSING / FALLBACKS
      // ==========================================
      case 'serratus anterior':
        return MuscleVisuals(
            backgroundColor: Colors.lightGreen.shade50, textColor: Colors.lightGreen.shade800, imagePath: 'assets/icons/serratus anterior.png');
      
      case 'cardiovascular system':
        return MuscleVisuals(
            backgroundColor: Colors.red.shade50, textColor: Colors.red.shade700, imagePath: 'assets/icons/cardiovascular system.png');

      default:
        return MuscleVisuals(
            backgroundColor: Colors.grey.shade100, textColor: Colors.grey.shade700, imagePath: 'assets/icons/fallback.png');
    }
  }
}