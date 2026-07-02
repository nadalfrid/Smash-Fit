import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightController with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _userSubscription;
  StreamSubscription? _authSubscription;
  StreamSubscription? _historySubscription;

  List<FlSpot> _weightHistorySpots = [];

  double _currentWeight = 0.0;
  double _baselineWeight = 0.0;
  double _targetWeight = 0.0;
  bool _isMilestoneAchieved = false;

  // 🟢 GETTERS: Cleanly expose state to the UI
  double get currentWeight => _currentWeight;
  double get baselineWeight => _baselineWeight;
  double get targetWeight => _targetWeight;
  bool get isMilestoneAchieved => _isMilestoneAchieved;

  List<FlSpot> get weightHistorySpots => _weightHistorySpots;
  
  // Expose the raw milestone target (e.g., 5kg for a 100kg user) in case you want to show it in the UI later
  double get milestoneTargetAmount => _baselineWeight * 0.05;

  WeightController() {
    // 🌟 SMART LIFECYCLE: Mirrors your DietController logic to wake up on login
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _initRealtimeListener(user.uid);
      } else {
        clearSession();
      }
    });
  }

  void _initRealtimeListener(String uid) {
    _userSubscription?.cancel();
    
    _userSubscription = _db.collection('users').doc(uid).snapshots().listen(
      (snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          _currentWeight = (data['weight'] ?? 0).toDouble();
          
          // 🟢 STRICT ANCHOR LOGIC: Read-only access to baseline
          final dynamic dbBaseline = data['baselineWeight'];
          
          if (dbBaseline == null || (dbBaseline as num) == 0) {
            // If missing in DB, use current weight as the baseline IN MEMORY ONLY.
            // DO NOT update the database here.
            _baselineWeight = _currentWeight;
          } else {
            // If it exists, read it and NEVER overwrite it.
            _baselineWeight = dbBaseline.toDouble();
          }
          
          _targetWeight = (data['targetWeight'] ?? _currentWeight).toDouble();
          
          _calculateMilestone();
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint("WeightController background stream dropped safely: $error");
      },
    );

    _listenToWeightHistory(uid); 
  }

  void _listenToWeightHistory(String uid) {
    _historySubscription?.cancel();
    
    _historySubscription = _db
        .collection('users')
        .doc(uid)
        .collection('weight_history')
        .orderBy('timestamp', descending: true) // Get newest first
        .limit(7) // Only grab the last 7 entries
        .snapshots()
        .listen((snap) {
          print("📡 Snapshot received! Documents found: ${snap.docs.length}"); 
          
          if (snap.docs.isEmpty) {
            print("⚠️ No history found in collection.");
            _weightHistorySpots = [];
            notifyListeners();
            return;
          }

        // Reverse the list so the oldest is at index 0 (left side of chart)
        final reversedDocs = snap.docs.reversed.toList();
        
        List<FlSpot> spots = [];
        for (int i = 0; i < reversedDocs.length; i++) {
          final data = reversedDocs[i].data();
          final double loggedWeight = (data['weight'] ?? 0).toDouble();
          
          // X is the index (0 to 6), Y is the actual weight
          spots.add(FlSpot(i.toDouble(), loggedWeight)); 
        }

        _weightHistorySpots = spots;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Error streaming weight history: $error");
      },
    );
  }

  // 🧮 THE BUSINESS LOGIC: Isolated from the UI
  void _calculateMilestone() {
    // If the baseline or target are 0, we can't run the math safely
    if (_baselineWeight == 0 || _targetWeight == 0) {
      _isMilestoneAchieved = false;
      return;
    }

    // Standard clinical 5% milestone
    double dynamicThreshold = _baselineWeight * 0.05;

    if (_targetWeight < _baselineWeight) {
      // 📉 Weight Loss Direction
      _isMilestoneAchieved = (_baselineWeight - _currentWeight) >= dynamicThreshold;
    } else if (_targetWeight > _baselineWeight) {
      // 📈 Weight Gain Direction
      _isMilestoneAchieved = (_currentWeight - _baselineWeight) >= dynamicThreshold;
    } else {
      // ⚖️ Maintenance / No Goal
      _isMilestoneAchieved = false;
    }
  }

  // 💾 THE SAVE ACTION: Keeps database writes out of the UI
  Future<void> saveNewWeight(double newWeight) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    try {
      // 1. Initialize a WriteBatch for atomic database operations
      WriteBatch batch = _db.batch();

      // 2. Reference to the master user profile
      DocumentReference userRef = _db.collection('users').doc(uid);
      
      // 3. Reference to a brand new document inside the 'weight_history' subcollection
      DocumentReference historyRef = _db.collection('users').doc(uid).collection('weight_history').doc();

      // 4. Operation A: Update the fluid weight in the master profile
      batch.update(userRef, {
        'weight': newWeight.toInt(),
      });

      // 5. Operation B: Log the historical snapshot
      batch.set(historyRef, {
        'weight': newWeight.toDouble(), // Keeping double for precise chart rendering later
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 6. Commit both operations to the cloud simultaneously
      await batch.commit();
      
      debugPrint("✅ Weight successfully updated and historical log created.");
    } catch (e) {
      debugPrint("❌ Error updating fluid weight in controller: $e");
      rethrow; // Rethrowing allows the UI to catch the error and show the Snackbar
    }
  }

  void clearSession() {
    _userSubscription?.cancel();
    _historySubscription?.cancel();
    _currentWeight = 0.0;
    _baselineWeight = 0.0;
    _targetWeight = 0.0;
    _isMilestoneAchieved = false;
    _weightHistorySpots = []; 
    notifyListeners();
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    _historySubscription?.cancel(); 
    super.dispose();
  }
}