import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/health_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import './diet_controller.dart';
import './history/workout_history_controller.dart';

class AuthController with ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();

  bool _isLoading = false;
  String? _errorMessage;

  // --- NEW: Isolated Live Preview States for true MVC ---
  double _signUpBmi = 0.0;
  double _signUpTdee = 0.0;

  double _editProfileBmi = 0.0;
  double _editProfileTdee = 0.0;

  // Getters to read states safely from the views
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  double get signUpBmi => _signUpBmi;
  double get signUpTdee => _signUpTdee;

  double get editProfileBmi => _editProfileBmi;
  double get editProfileTdee => _editProfileTdee;

  /// Updates live health stats exclusively for the Sign-Up screen
  void updateSignUpPreview({
    required int age,
    required String weightStr,
    required String heightStr,
    required String genderName,
    required String activityLevelName,
  }) {
    double weight = double.tryParse(weightStr) ?? 0;
    double height = double.tryParse(heightStr) ?? 0;

    _signUpBmi = HealthService.calculateBMI(weight, height);
    _signUpTdee = HealthService.calculateTDEE(
      age: age,
      weight: weight,
      height: height,
      gender: genderName,
      activityLevel: activityLevelName,
    );
    notifyListeners(); // Alerts the Sign-Up view to update instantly
  }

  /// Updates live health stats exclusively for the Edit Profile screen
  void updateEditProfilePreview({
    required int age,
    required String weightStr,
    required String heightStr,
    required String genderName,
    required String activityLevelName,
  }) {
    double weight = double.tryParse(weightStr) ?? 0;
    double height = double.tryParse(heightStr) ?? 0;

    _editProfileBmi = HealthService.calculateBMI(weight, height);
    _editProfileTdee = HealthService.calculateTDEE(
      age: age,
      weight: weight,
      height: height,
      gender: genderName,
      activityLevel: activityLevelName,
    );
    notifyListeners(); // Alerts the Edit Profile view to update instantly
  }

  /// Pre-initializes the Edit Profile preview values when opening the screen
  void initializeEditProfileValues(UserModel user) {
    _editProfileBmi = user.bmi;
    _editProfileTdee = user.tdee;
    // Don't call notifyListeners here as it's usually called during initState setup
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String heightStr,
    required String weightStr,
    required Gender gender,
    required ActivityLevel activityLevel,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      double weight = double.tryParse(weightStr) ?? 0;
      double height = double.tryParse(heightStr) ?? 0;

      double bmi = HealthService.calculateBMI(weight, height);
      double tdee = HealthService.calculateTDEE(
        age: age,
        weight: weight,
        height: height,
        gender: gender.name,
        activityLevel: activityLevel.name,
      );

      UserModel user = UserModel(
        uid: '', 
        email: email,
        name: name,
        gender: gender,
        activityLevel: activityLevel,
        age: age,
        weight: weight,
        height: height,
        bmi: bmi,
        tdee: tdee,
      );

      await _firebase.signUp(user: user, password: password);
      return true; 
    } catch (e) {
      _setErrorMessage(e.toString().replaceAll("Exception:", ""));
      return false; 
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String name,
    required int age,
    required String heightStr,
    required String weightStr,
    required Gender gender,
    required ActivityLevel activityLevel,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      double weight = double.tryParse(weightStr) ?? 0;
      double height = double.tryParse(heightStr) ?? 0;

      double bmi = HealthService.calculateBMI(weight, height);
      double tdee = HealthService.calculateTDEE(
        age: age,
        weight: weight,
        height: height,
        gender: gender.name,
        activityLevel: activityLevel.name,
      );

      await _firebase.updateUserProfile(
        name: name,
        age: age,
        height: height,
        weight: weight,
        gender: gender,
        activityLevel: activityLevel,
        bmi: bmi,
        tdee: tdee,
      );
      return true;
    } catch (e) {
      _setErrorMessage(e.toString().replaceAll("Exception:", ""));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  Future<void> logOutUserSession(BuildContext context) async {
    try {
      // 1. Terminate all background listening channels first to prevent resource memory leaks
      Provider.of<DietController>(context, listen: false).clearSession();
      Provider.of<WorkoutHistoryController>(context, listen: false).clearSession();

      // 2. Erase the active authentication session token from Firebase
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Error performing central session teardown: $e");
      rethrow;
    }
  }

}