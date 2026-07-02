enum Gender { male, female }

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive,
  extraActive,
}

// --- NEW MVC EXTENSION: Centralizes Enum Text Formatting ---
extension ActivityLevelExtension on ActivityLevel {
  /// Simple names used in ProfileView (e.g., "Very Active")
  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary: return "Sedentary";
      case ActivityLevel.light: return "Light";
      case ActivityLevel.moderate: return "Moderate";
      case ActivityLevel.active: return "Active";
      case ActivityLevel.veryActive: return "Very Active";
      case ActivityLevel.extraActive: return "Extra Active";
    }
  }

  /// Full descriptions used in Dropdowns (e.g., "Sedentary: Little or no exercise")
  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return "Sedentary: Little or no exercise";
      case ActivityLevel.light:
        return "Light: Exercise 1-3 times/week";
      case ActivityLevel.moderate:
        return "Moderate: Exercise 4-5 times/week";
      case ActivityLevel.active:
        return "Active: Daily or intense 3-4 times/week";
      case ActivityLevel.veryActive:
        return "Very Active: Intense exercise 6-7 times/week";
      case ActivityLevel.extraActive:
        return "Extra Active: Very intense or physical job";
    }
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final Gender gender;
  final ActivityLevel activityLevel;
  final int age;
  final double weight;
  final double height;
  final double tdee; 
  final double bmi;
  final double? targetWeight;
  final double? baselineWeight;  

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.gender,
    required this.activityLevel,
    required this.age,
    required this.weight,
    required this.height,
    required this.tdee,
    required this.bmi,
    this.targetWeight,
    this.baselineWeight,
  });

  String get bmiCategory {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      gender: Gender.values.firstWhere((e) => e.name == data['gender']),
      activityLevel: ActivityLevel.values.firstWhere((e) => e.name == data['activityLevel']),
      age: data['age'] ?? 0,
      weight: (data['weight'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      tdee: (data['tdee'] ?? 0).toDouble(),
      bmi: (data['bmi'] ?? 0).toDouble(),
      targetWeight: data['targetWeight'] != null ? (data['targetWeight']).toDouble() : null,
      baselineWeight: data['baselineWeight'] != null ? (data['baselineWeight']).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'gender': gender.name, 
      'activityLevel': activityLevel.name,
      'age': age,
      'weight': weight,
      'height': height,
      'tdee': tdee,
      'bmi': bmi,
      if (targetWeight != null) 'targetWeight': targetWeight,
      if (baselineWeight != null) 'baselineWeight': baselineWeight,
    };
  }
}