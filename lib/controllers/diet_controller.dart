import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diet_model.dart';
import '../models/user_model.dart';
import '../services/food_service.dart';
import '../services/health_service.dart';

class DietController with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FoodService _foodService = FoodService();

  List<MealCategory> _meals = [];
  DateTime _historySelectedDate = DateTime.now();
  List<MealCategory> _historyMeals = [];

  UserModel? _userProfile;
  List<dynamic> _searchResults = [];
  bool _isSearchLoading = false;
  
  StreamSubscription? _dietSubscription;
  StreamSubscription? _userSubscription;
  StreamSubscription? _authSubscription; // 🌟 NEW: Listens for login/logout events

  Set<String> _datesWithFood = {}; 

  int _usdaPage = 1;
  bool _canLoadMore = true;

  // GETTERS
  List<MealCategory> get meals => _meals;
  int get currentCalories => _meals.fold(0, (sum, m) => sum + m.totalCalories);
  int get currentProtein => _meals.expand((m) => m.items).fold(0, (sum, i) => sum + i.protein);
  int get currentCarbs => _meals.expand((m) => m.items).fold(0, (sum, i) => sum + i.carbs);
  int get currentFat => _meals.expand((m) => m.items).fold(0, (sum, i) => sum + i.fat);

  DateTime get historySelectedDate => _historySelectedDate;
  List<MealCategory> get historyMeals => _historyMeals;
  Set<String> get datesWithFood => _datesWithFood;
  
  int get historyCalories => _historyMeals.fold(0, (sum, m) => sum + m.totalCalories);
  int get historyProtein => _historyMeals.expand((m) => m.items).fold(0, (sum, i) => sum + i.protein);
  int get historyCarbs => _historyMeals.expand((m) => m.items).fold(0, (sum, i) => sum + i.carbs);
  int get historyFat => _historyMeals.expand((m) => m.items).fold(0, (sum, i) => sum + i.fat);

  List<dynamic> get searchResults => _searchResults;
  bool get isSearchLoading => _isSearchLoading;
  UserModel? get userProfile => _userProfile;
  int get targetCalories => (_userProfile?.tdee ?? 2000).toInt();
  
  String get proteinRange => _userProfile == null 
      ? "---" 
      : HealthService.calculateProteinRange(
          age: _userProfile!.age, 
          weight: _userProfile!.weight, 
          gender: _userProfile!.gender);

  int get maxProtein => int.tryParse(
        proteinRange.split('-').last.replaceAll(RegExp(r'[^0-9]'), '')
      ) ?? 150;

  Map<String, int> get carbsRange => HealthService.calculateCarbsRange(_userProfile?.tdee ?? 2000);
  Map<String, int> get fatRange => HealthService.calculateFatRange(_userProfile?.tdee ?? 2000, _userProfile?.age ?? 25);

  DietController() {
    // 🌟 SMART LIFECYCLE: Controller wakes up automatically when a user logs in!
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _initRealtimeListener(); // Turn engine ON
      } else {
        clearSession(); // Turn engine OFF securely
      }
    });
  }

  void clearSession() {
    _dietSubscription?.cancel();
    _userSubscription?.cancel();
    _meals = [];
    _historyMeals = [];
    _userProfile = null;
    _datesWithFood = {};
    notifyListeners();
  }

  void updateHistoryDate(DateTime newDate) {
    _historySelectedDate = newDate;
    _listenToDietItems(); 
    notifyListeners(); 
  }

  void _initRealtimeListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    _userSubscription = _db.collection('users').doc(user.uid).snapshots().listen(
      (snap) {
        if (snap.exists) {
          _userProfile = UserModel.fromMap(snap.data()!, user.uid);
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint("Suppressed user profile background stream drop payload safely.");
      },
    );

    _listenToDietItems(); 
  }

  void _listenToDietItems() {
    _dietSubscription?.cancel(); 
    final user = _auth.currentUser;
    if (user == null) return;

    _dietSubscription = _db.collection('users').doc(user.uid).collection('diet_items').snapshots().listen(
      (snap) {
        final now = DateTime.now();
        
        final todaySkeleton = [
          MealCategory(id: 'Breakfast', title: 'Breakfast', items: []),
          MealCategory(id: 'Lunch', title: 'Lunch', items: []),
          MealCategory(id: 'Dinner', title: 'Dinner', items: []),
          MealCategory(id: 'Snacks', title: 'Snacks', items: []),
        ];

        final historySkeleton = [
          MealCategory(id: 'Breakfast', title: 'Breakfast', items: []),
          MealCategory(id: 'Lunch', title: 'Lunch', items: []),
          MealCategory(id: 'Dinner', title: 'Dinner', items: []),
          MealCategory(id: 'Snacks', title: 'Snacks', items: []),
        ];

        final Set<String> updatedLoggedDates = {};
        final String selectedTargetToken = "${_historySelectedDate.year}-${_historySelectedDate.month.toString().padLeft(2, '0')}-${_historySelectedDate.day.toString().padLeft(2, '0')}";

        for (var doc in snap.docs) {
          final food = FoodItem.fromMap(doc.id, doc.data());
          final String dotKey = "${food.timestamp.year}-${food.timestamp.month.toString().padLeft(2, '0')}-${food.timestamp.day.toString().padLeft(2, '0')}";
          updatedLoggedDates.add(dotKey);

          final bool isToday = food.timestamp.year == now.year &&
                              food.timestamp.month == now.month &&
                              food.timestamp.day == now.day;
          if (isToday) {
            todaySkeleton.firstWhere((m) => m.id == food.mealCategory, orElse: () => todaySkeleton.last).items.add(food);
          }

          final bool isHistoryDay = (dotKey == selectedTargetToken);
          if (isHistoryDay) {
            historySkeleton.firstWhere((m) => m.id == food.mealCategory, orElse: () => historySkeleton.last).items.add(food);
          }
        }
        
        _datesWithFood = updatedLoggedDates;
        _meals = todaySkeleton;
        _historyMeals = historySkeleton;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Suppressed diet logs background stream drop payload safely.");
      },
    );
  }

  Future<List<FoodItem>> getDietLogsInWindow(DateTime startDate, DateTime endDate) async {
    final user = _auth.currentUser; if (user == null) return [];
    try {
      final int startMillis = startDate.millisecondsSinceEpoch;
      final int endMillis = endDate.millisecondsSinceEpoch;
      final querySnapshot = await _db.collection('users').doc(user.uid).collection('diet_items').where('timestamp', isGreaterThanOrEqualTo: startMillis).where('timestamp', isLessThanOrEqualTo: endMillis).get();
      return querySnapshot.docs.map((doc) => FoodItem.fromMap(doc.id, doc.data())).toList();
    } catch (e) { return []; }
  }
  
  Future<void> searchMalaysia(String query) async { 
    if (query.isEmpty) { 
      _searchResults = []; 
      notifyListeners(); 
      return; 
    } 
    
    _isSearchLoading = true; 
    notifyListeners(); 
    
    try { 
      final List<dynamic> results = await _foodService.searchMalaysiaFood(query); 
      // 🌟 CHANGED: Source is now LOCAL. FoodDetailsView math will still work perfectly.
      _searchResults = results.map((item) => Map<String, dynamic>.from({...item, "source": "LOCAL"})).toList(); 
    } catch (e) { 
      _searchResults = []; 
    } finally { 
      _isSearchLoading = false; 
      notifyListeners(); 
    } 
  }

  Future<void> searchUSDA(String query, {bool isNewSearch = true}) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    if (isNewSearch) {
      _usdaPage = 1;
      _searchResults = [];
      _canLoadMore = true;
    }

    if (!_canLoadMore || (_isSearchLoading && !isNewSearch)) return;

    _isSearchLoading = true;
    notifyListeners();

    try {
      final List<dynamic> results = await _foodService.searchUSDAFood(query, _usdaPage);
      
      if (results.isEmpty) {
        _canLoadMore = false;
      } else {
        final List<Map<String, dynamic>> mappedResults = results.map<Map<String, dynamic>>((food) {
          final nutrients = food['foodNutrients'] as List? ?? [];
          final String dataType = food['dataType'] ?? "";

          double findVal(int id, String backupNum) {
            final n = nutrients.firstWhere(
              (n) => n['nutrientId'] == id || n['number'] == backupNum,
              orElse: () => null,
            );
            return (n?['value'] ?? n?['amount'] ?? 0.0).toDouble();
          }

          double p = findVal(1003, "203");
          double f = findVal(1004, "204");
          double c = findVal(1005, "205");
          double cal = findVal(1008, "208");

          if (cal <= 0 && (p > 0 || f > 0 || c > 0)) {
            cal = (p * 4) + (c * 4) + (f * 9);
          }

          return Map<String, dynamic>.from({
            "id": food['fdcId'].toString(),
            "name": food['description'],
            "calories": cal,
            "protein": p,
            "fat": f,
            "carbs": c,
            "serving": "100",
            "unit": food['servingSizeUnit'] ?? "g",
            "source": "USDA",
            "dataType": dataType,
          });
        }).toList();

        if (isNewSearch) {
          _searchResults = mappedResults;
        } else {
          _searchResults.addAll(mappedResults);
        }

        _searchResults.sort((a, b) {
          int priority(String type) {
            if (type == "Foundation") return 0;
            if (type == "SR Legacy") return 1;
            return 2;
          }
          return priority(a['dataType'] ?? "").compareTo(priority(b['dataType'] ?? ""));
        });

        _usdaPage++;
      }
    } catch (e) {
      // Optional: Log errors here if needed
    } finally {
      _isSearchLoading = false;
      notifyListeners();
    }
  }

  Future<void> logFood(String category, FoodItem item, {required DateTime targetDate}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    item.mealCategory = category;
    
    final currentFocusTime = DateTime.now();
    item.timestamp = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      currentFocusTime.hour,
      currentFocusTime.minute,
      currentFocusTime.second,
    );

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('diet_items')
        .add(item.toMap());
  }

  Future<void> updateFood(FoodItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('diet_items')
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> deleteFood(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('diet_items')
        .doc(id)
        .delete();
  }
  @override 
  void dispose() { 
    _authSubscription?.cancel(); // 🌟 NEW: Cleanup auth listener
    _dietSubscription?.cancel(); 
    _userSubscription?.cancel(); 
    super.dispose(); 
  }
}