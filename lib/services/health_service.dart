import 'package:smash_fit/models/user_model.dart';

class HealthService {
  static double calculateBMI(double weight, double height) {
    if (height <= 0) return 0.0;
    double heightInMeters = height / 100;
    return double.parse((weight / (heightInMeters * heightInMeters)).toStringAsFixed(1));
  }

  static double calculateTDEE({
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activityLevel,
  }) {
    // Mifflin-St Jeor Equation
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    bmr = (gender == 'male') ? bmr + 5 : bmr - 161;

    // Activity Multipliers
    Map<String, double> factors = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'veryActive': 1.9,
      'extraActive': 1.9,
    };

    return double.parse((bmr * (factors[activityLevel] ?? 1.2)).toStringAsFixed(0));
  }

  /// Calculates the Protein Range based on RDA (Age/Gender) and Weight (Activity)
  static String calculateProteinRange({
    required int age,
    required double weight,
    required Gender gender,
  }) {
    // 1. Determine RDA "Floor" based on your provided image table
    int rdaFloor = 56; // Default for Adult Men

    if (age <= 3) {
      rdaFloor = 13;
    } else if (age <= 8) {
      rdaFloor = 19;
    } else if (age <= 13) {
      rdaFloor = 34;
    } else if (age <= 18) {
      // Logic for teens based on Enum
      rdaFloor = (gender == Gender.male) ? 52 : 46;
    } else {
      // Logic for adults based on Enum
      rdaFloor = (gender == Gender.male) ? 56 : 46;
    }

    // 2. Determine "Ceiling" based on physical activity (1.8g/kg)
    // Using 1.8g/kg as the upper limit for active individuals as per your explanation
    int proteinCeiling = (weight * 1.8).round();

    // 3. Safety check: If weight is very low, ensure ceiling isn't below the RDA floor
    if (proteinCeiling < rdaFloor) {
      proteinCeiling = rdaFloor + 10;
    }

    return "$rdaFloor - ${proteinCeiling}g";
  }

  static Map<String, int> calculateCarbsRange(double tdee) {
    // Guidelines: 45% to 65% of total calories
    // 1g carb = 4 kcal
    int min = ((tdee * 0.45) / 4).round();
    int max = ((tdee * 0.65) / 4).round();

    // RDA Safety: Minimum 130g
    if (min < 130) min = 130;
    if (max < 130) max = 150; 

    return {'min': min, 'max': max};
  }

  static Map<String, int> calculateFatRange(double tdee, int age) {
    double minPercentage;
    double maxPercentage;

    // Logic based on your uploaded image table
    if (age <= 3) {
      minPercentage = 0.30;
      maxPercentage = 0.40;
    } else if (age <= 18) {
      minPercentage = 0.25;
      maxPercentage = 0.35;
    } else {
      minPercentage = 0.20;
      maxPercentage = 0.35;
    }

    // 1g fat = 9 kcal
    int minGrams = ((tdee * minPercentage) / 9).round();
    int maxGrams = ((tdee * maxPercentage) / 9).round();

    return {'min': minGrams, 'max': maxGrams};
  }
}