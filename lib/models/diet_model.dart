class FoodItem {
  String id; // Firestore Doc ID
  String? externalId; // Generic ID for any API
  String name;
  String mealCategory;
  int calories;
  int protein;
  int carbs;
  int fat;
  double amount;
  String unit;
  DateTime timestamp; // 🌟 ADDED: Proper typed field for easy date-window filtering

  FoodItem({
    required this.id,
    this.externalId,
    required this.name,
    required this.mealCategory,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.amount = 1.0,
    this.unit = "serving",
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'externalId': externalId,
      'name': name,
      'mealCategory': mealCategory,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'amount': amount,
      'unit': unit,
      // 🔄 Keeps your raw millisecond integer storage intact
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory FoodItem.fromMap(String id, Map<String, dynamic> map) {
    // 🔄 Converts your raw database integer back into a usable Dart DateTime
    final int rawMillis = map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    return FoodItem(
      id: id,
      externalId: map['externalId']?.toString(),
      name: map['name'] ?? '',
      mealCategory: map['mealCategory'] ?? 'Snacks',
      calories: map['calories']?.toInt() ?? 0,
      protein: map['protein']?.toInt() ?? 0,
      carbs: map['carbs']?.toInt() ?? 0,
      fat: map['fat']?.toInt() ?? 0,
      amount: (map['amount'] ?? 1.0).toDouble(),
      unit: map['unit'] ?? 'serving',
      timestamp: DateTime.fromMillisecondsSinceEpoch(rawMillis),
    );
  }
}

class MealCategory {
  String id;
  String title;
  List<FoodItem> items;
  MealCategory({required this.id, required this.title, required this.items});
  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
}

// ==========================================
// 🌟 NEWLY ADDED ANALYSIS HELPER LAYER
// ==========================================

/// Holds an entire single day's nutrition summary for weekly macro calculations
class DailyDietLog {
  final DateTime date;
  final List<FoodItem> items;

  DailyDietLog({required this.date, required this.items});

  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  int get totalProtein => items.fold(0, (sum, item) => sum + item.protein);
  int get totalCarbs => items.fold(0, (sum, item) => sum + item.carbs);
  int get totalFat => items.fold(0, (sum, item) => sum + item.fat);
}