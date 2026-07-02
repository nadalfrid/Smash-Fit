import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🟢 Sync integration
import '../../models/workout_plan_model.dart';
import '../../views/workout/workout_questionnaire_view.dart';
import '../../views/workout/all_plans_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutQuestionnaireController extends ChangeNotifier {
  final PageController pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  
  int _currentPage = 0;
  int get currentPage => _currentPage;
  final int totalPages = 5;

  // 🟢 Loading state tracking flag
  bool _isLoading = false;
  bool get isLoading => _isLoading; 

  String? _selectedGoal;
  String? get selectedGoal => _selectedGoal;

  String? _selectedExperience;
  String? get selectedExperience => _selectedExperience;

  String? _selectedFrequency;
  String? get selectedFrequency => _selectedFrequency;

  String? _selectedCommitment;
  String? get selectedCommitment => _selectedCommitment;
  
  double _currentWeight = 75.0;
  double get currentWeight => _currentWeight;

  double _targetWeight = 70.0;
  double get targetWeight => _targetWeight;

  int _currentDayIndex = 0;
  int get currentDayIndex => _currentDayIndex;

  List<WorkoutPlan> _recommendedPlans = [];
  List<WorkoutPlan> get recommendedPlans => _recommendedPlans;
  
  // 🟢 Dynamic reactive list linked directly to your cloud data
  List<WorkoutPlan> _allPlans = [];
  List<WorkoutPlan> get allPlans => _allPlans;

  // =====================================================================
  // 🟢 ASYNCHRONOUS FIRESTORE CORES
  // =====================================================================
  Future<void> fetchMasterPlansFromFirestore() async {
    _isLoading = true;
    notifyListeners();

    try {
      print("📡 Fetching production master workout splits from Cloud Architecture...");
      QuerySnapshot querySnapshot = await _firestore.collection('workout_plans').get();
      
      // Map Firestore documents directly back into your custom structural models
      _allPlans = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return WorkoutPlan.fromMap(data); 
      }).toList();

      print("🎯 Dynamic Cloud Load complete. ${_allPlans.length} plans compiled.");
    } catch (e) {
      print("❌ Critical network parsing failure loading plans: $e");
      _allPlans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setGoal(String goal) { _selectedGoal = goal; notifyListeners(); }
  void setExperience(String exp) { _selectedExperience = exp; notifyListeners(); }
  void setFrequency(String freq) { _selectedFrequency = freq; notifyListeners(); }
  
// 🟢 FIXED: Synchronous setter avoids async layout lag and page reset loops
  void setCommitment(String comm) { 
    _selectedCommitment = comm; 
    generateRecommendations();
    notifyListeners(); 
  }
  
  void setCurrentWeight(double val) { _currentWeight = val; notifyListeners(); }
  void setTargetWeight(double val) { _targetWeight = val; notifyListeners(); }

  bool get canProceed {
    if (_currentPage == 0 && _selectedGoal == null) return false;
    if (_currentPage == 1 && _selectedExperience == null) return false;
    if (_currentPage == 2 && _selectedFrequency == null) return false;
    if (_currentPage == 3 && _selectedCommitment == null) return false;
    return true;
  }

  void updatePage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < totalPages - 1) {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousPage(BuildContext context) {
    if (_currentPage > 0) {
      pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context); 
    }
  }

  // --- RECOMMENDED GENERATION ENGINE (UNCHANGED FUNCTIONALITY) ---
  void generateRecommendations() {
    if (_allPlans.isEmpty) return;

    _recommendedPlans = _allPlans.where((plan) {
      bool matchesDifficulty = _selectedExperience != null 
          ? plan.difficulty == _selectedExperience 
          : true;
      
      bool matchesFrequency = true;
      if (_selectedFrequency != null) {
        int selectedDaysCount = int.parse(_selectedFrequency!.substring(0, 1));
        matchesFrequency = plan.weeklyRoutine != null && plan.weeklyRoutine!.length == selectedDaysCount;
      }
      
      return matchesDifficulty && matchesFrequency; 
    }).toList();
    
    if (_recommendedPlans.isEmpty && _selectedExperience != null) {
       _recommendedPlans = _allPlans.where((plan) => plan.difficulty == _selectedExperience).toList();
    }

    if (_recommendedPlans.isEmpty) {
        _recommendedPlans = _allPlans.take(2).toList();
    }

    _recommendedPlans = _recommendedPlans.take(2).toList();
  }

  

  Future<void> incrementWorkoutProgress() async {
    _currentDayIndex++;
    notifyListeners();

    // 🟢 NEW: Silently sync the progress index to the cloud so it survives app restarts
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('planned_workouts')
            .doc('current_plan')
            .update({'currentDayIndex': _currentDayIndex});
      } catch (e) {
        print("⚠️ Failed to sync progress index to cloud: $e");
      }
    }
  }

  // =====================================================================
  // 🟢 PERSISTENCE BRIDGE: Saves the chosen plan under the user's private space
  // =====================================================================
  Future<void> saveUserSelectedPlanToCloud(WorkoutPlan selectedPlan) async {
    // 1. Grab the active user's authenticated ID from the current context state
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      print("❌ State Error: No authenticated user found logged in. Save aborted.");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print("💾 Saving Selected Plan [${selectedPlan.title}] to Cloud Storage for UID: $uid");

      // 2. Map the data cleanly into a standard Map structure
      final Map<String, dynamic> userPlanData = {
        'assignedPlanId': selectedPlan.id,
        'title': selectedPlan.title,
        'currentDayIndex': 0,
        'goal': selectedPlan.goal,
        'difficulty': selectedPlan.difficulty,
        'durationText': selectedPlan.durationText,
        'timestampAssigned': FieldValue.serverTimestamp(),
        // Map out the structured weekly routine array
        'weeklyRoutine': selectedPlan.weeklyRoutine?.map((day) => {
          'dayName': day.dayName,
          'exercises': day.exercises.map((ex) => {
            'name': ex.name,
            'targetGroup': ex.targetGroup,
            'prescribedSetsReps': ex.prescribedSetsReps,
            'exerciseId': ex.exerciseId, // Keeps your perfect 4-digit ID!
          }).toList()
        }).toList(),
      };

      // 1. Commit the workout plan to the subcollection
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('planned_workouts')
          .doc('current_plan')
          .set(userPlanData, SetOptions(merge: true));

      await _firestore.collection('users').doc(uid).set({
        'targetWeight': _targetWeight.toInt(),
        'baselineWeight': _currentWeight.toInt(),
        'fitnessGoal': _selectedGoal,
        'experienceLevel': _selectedExperience,
      }, SetOptions(merge: true));

      print("🎯 Plan linked successfully. Data will survive app resets.");
    } catch (e) {
      print("❌ Failed to commit plan configuration to Firestore: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =====================================================================
  // 🟢 STARTUP RETRIEVAL BRIDGE: Loads an existing plan from the cloud
  // =====================================================================
  Future<void> loadUserActivePlanFromCloud() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      print("ℹ️ Startup: No logged-in user found. Skipping plan retrieval.");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print("📡 Startup: Checking cloud database for active plan for UID: $uid");
      
      DocumentSnapshot planDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('planned_workouts')
          .doc('current_plan')
          .get();

      if (planDoc.exists && planDoc.data() != null) {
        final data = planDoc.data() as Map<String, dynamic>;
        
        // 1. Reconstruct your clean model directly from the retrieved cloud document
        WorkoutPlan activePlan = WorkoutPlan.fromMap(data);
        _currentDayIndex = data['currentDayIndex'] ?? 0;
        
        // 2. Hydrate your controller's recommended list so the dashboard populates instantly
        _recommendedPlans = [activePlan];
        
        print("🎯 Startup success: Permanent plan [${activePlan.title}] loaded into memory.");
      } else {
        print("ℹ️ Startup: No saved workout plan found in the cloud for this user account.");

        _recommendedPlans = []; 
        _currentDayIndex = 0;
      }
    } catch (e) {
      print("❌ Error loading saved user plan from cloud state: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void reset() {
    _currentPage = 0; _selectedGoal = null; _selectedExperience = null;
    _selectedFrequency = null; _selectedCommitment = null; _recommendedPlans = [];
    _currentDayIndex = 0;
    if (pageController.hasClients) { pageController.jumpToPage(0); }
    notifyListeners();
  }

  void handlePlanResetAndNavigation(BuildContext context) {
    reset(); 
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WorkoutQuestionnaireView()));
  }

  void navigateToAllPlansCatalog(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AllPlansView()));
  }


  void clearSession() {
    _recommendedPlans = [];
    _currentDayIndex = 0;
    _selectedGoal = null;
    _selectedExperience = null;
    _selectedFrequency = null;
    _selectedCommitment = null;
    notifyListeners();
  }
  
  /// Deletes the active workout plan from Firestore and clears local state
  Future<bool> deleteActivePlanFromCloud() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      // 1. Wipe the plan document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('planned_workouts')
          .doc('current_plan')
          .delete();

      // 2. 🟢 CLEAR LOCAL CONTROLLER STATE
      _recommendedPlans = []; // This triggers the UI to show the "Generate Workout" button again!
      _currentDayIndex = 0;
        
      notifyListeners();
      return true;
    } catch (e) {
      print("Error deleting plan from cloud: $e");
      return false;
    }
  }

  // 🟢 NEW: Fetches the user's real weight from the master profile to set the sliders safely
  Future<void> initializeUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        
        // Grab the user's master weight, or safely fallback to 75.0 if something goes wrong
        double masterWeight = (data['weight'] ?? 75.0).toDouble();

        // Sync BOTH sliders to the user's actual master weight!
        _currentWeight = masterWeight;
        _targetWeight = masterWeight;
        
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching master profile for questionnaire sliders: $e");
    }
  }
  
}