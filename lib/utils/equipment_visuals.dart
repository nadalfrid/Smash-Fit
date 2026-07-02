import 'package:flutter/material.dart';

class EquipmentVisuals {
  /// Maps an equipment name string to a clean, corresponding Material Icon
  static IconData getIcon(String equipmentName) {
    switch (equipmentName.toLowerCase().trim()) {
      case 'barbell':
        return Icons.fitness_center_rounded; // Best representation for heavy bars
      case 'dumbbell':
      case 'dumbbells':
        return Icons.fitness_center_outlined;
      case 'cable':
      case 'cables':
        return Icons.linear_scale_rounded; // Represents pulley cables nicely
      case 'leverage machine':
      case 'machines':
        return Icons.settings_accessibility_rounded; // Represents mechanical tracks
      case 'smith machine':
        return Icons.sports_gymnastics_rounded;
      case 'body weight':
      case 'bodyweight':
        return Icons.accessibility_new_rounded; // Represents calisthenics / human form
      case 'bench':
        return Icons.chair_alt_rounded; // Simple representation of a training bench seat
      case 'squat rack':
        return Icons.grid_3x3_rounded; // Represents cage rails / metal structures
      case 'pull up bar':
      case 'pullup bar':
        return Icons.horizontal_rule_rounded; // High overhead bar anchor layout
      case 'dip bar':
        return Icons.unfold_more_rounded; // Parallel rails visual representation
      default:
        return Icons.handyman_rounded; // Safe global fallback icon for generic gear
    }
  }
}