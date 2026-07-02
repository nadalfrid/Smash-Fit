import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/workout_models.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  String? get currentUserId => _auth.currentUser?.uid;

  // 1. Clean Sign Up - Accepts a pre-built UserModel
  Future<void> signUp({required UserModel user, required String password}) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(
      email: user.email, 
      password: password
    );
    
    // Save the user data using the UID from Firebase Auth
    await _db.collection('users').doc(res.user!.uid).set(user.toMap());
  }

  // 2. Sign In
  Future<void> signIn(String email, String password) async => 
      await _auth.signInWithEmailAndPassword(email: email, password: password);

  // 3. Sign Out
  Future<void> signOut() async => await _auth.signOut();

  // 4. Get Data Stream
  Stream<UserModel> getUserStream() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots().map((snap) => UserModel.fromMap(snap.data()!, uid));
  }

  // 5. Update Profile - Added bmi and tdee parameters
  Future<void> updateUserProfile({
    String? name,
    int? age,
    double? height,
    double? weight,
    Gender? gender,           
    ActivityLevel? activityLevel, 
    double? bmi,
    double? tdee,
  }) async {
    String uid = _auth.currentUser!.uid;
    Map<String, dynamic> data = {};

    if (name != null) data['name'] = name;
    if (age != null) data['age'] = age;
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    if (gender != null) data['gender'] = gender.name; 
    if (activityLevel != null) data['activityLevel'] = activityLevel.name;
    if (bmi != null) data['bmi'] = bmi;
    if (tdee != null) data['tdee'] = tdee;

    await _db.collection('users').doc(uid).update(data);
  }

  // 6. Save Workout
  Future<void> saveWorkout(WorkoutLog workout) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return; 

    try {
      // Points to: users -> [userID] -> workouts -> [Auto-ID Document]
      await _db
          .collection('users')
          .doc(uid) 
          .collection('workouts') 
          .add(workout.toMap());
          
      print("Workout saved successfully!");
    } catch (e) {
      print("Error saving workout: $e");
      rethrow;
    }
  }

  // 7. Get Workouts Stream (Recent first)
  Stream<List<WorkoutLog>> getWorkoutsStream() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .orderBy('startTime', descending: true) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 🌟 NEW 7b. Get Workouts In Date Window (Optimized for Analysis Module Calculations)
  Future<List<WorkoutLog>> getWorkoutsInWindow(DateTime startDate, DateTime endDate) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      // Convert standard Dart DateTime items into native Firestore Timestamps safely
      final Timestamp startTimestamp = Timestamp.fromDate(startDate);
      final Timestamp endTimestamp = Timestamp.fromDate(endDate);

      final querySnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .where('startTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('startTime', isLessThanOrEqualTo: endTimestamp)
          .get();

      return querySnapshot.docs
          .map((doc) => WorkoutLog.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Error fetching date-bounded analytics history datasets: $e");
      return [];
    }
  }

  // 8. Update Existing Workout
  Future<void> updateWorkout(WorkoutLog workout) async {
    if (workout.id == null) return;
    String uid = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .doc(workout.id)
        .update(workout.toMap());
  }

  // 9. Delete Workout
  Future<void> deleteWorkout(String workoutId) async {
    String? uid = _auth.currentUser?.uid;
    
    if (uid == null) {
      throw Exception("User must be logged in to delete a workout.");
    }

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .doc(workoutId)
          .delete();
          
      print("Workout $workoutId deleted successfully from Firestore.");
    } catch (e) {
      print("Error deleting workout: $e");
      rethrow; 
    }
  }

  // --- 10. PASSWORD RESET ---
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}