import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  final String equipment;
  final String imageUrl;

  final List<String>? gifUrls;
  final String? overview;
  final List<String>? bodyParts;
  final List<String>? instructions;

  // --- NEW: WorkoutX Specific Fields ---
  final String? category;
  final String? difficulty;
  final String? mechanic;
  final String? force;
  final double? met;
  final double? caloriesPerMinute;
  final List<String>? secondaryMuscles;

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.equipment,
    this.imageUrl = "",
    this.gifUrls,
    this.overview,
    this.bodyParts,
    this.instructions,
    this.category,
    this.difficulty,
    this.mechanic,
    this.force,
    this.met,
    this.caloriesPerMinute,
    this.secondaryMuscles,
  });

  // --- 1. FACTORY FOR WORKOUTX API ---
  factory Exercise.fromApiJson(Map<String, dynamic> json) {
    return Exercise(
      id: (json['id'] ?? '').toString(),
      name: _capitalize(json['name'] ?? 'Unknown'),
      targetMuscle: _capitalize(json['target'] ?? ''),
      equipment: _capitalize(json['equipment'] ?? 'Bodyweight'),
      imageUrl: json['gifUrl'] ?? '',
      gifUrls: json['gifUrl'] != null ? [json['gifUrl']] : [],
      overview: json['description'] ?? '',
      bodyParts: json['bodyPart'] != null ? [_capitalize(json['bodyPart'])] : [],
      instructions: List<String>.from(json['instructions'] ?? []),
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] ?? []),
      category: json['category'],
      difficulty: json['difficulty'],
      mechanic: json['mechanic'],
      force: json['force'],
      met: (json['met'] as num?)?.toDouble(),
      caloriesPerMinute: (json['caloriesPerMinute'] as num?)?.toDouble(),
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // --- 2. FACTORY FOR FIRESTORE (LOADING HISTORY) ---
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['exerciseId'] ?? '', // Pointing to the clean database key
      name: map['name'] ?? 'Unknown Exercise',
      targetMuscle: map['targetMuscle'] ?? '',
      equipment: map['equipment'] ?? '',
      category: map['category'],
      bodyParts: List<String>.from(map['bodyParts'] ?? []),
      // Restricted fields safely return empty placeholders when reading history
      imageUrl: '',
      gifUrls: const [],
      overview: '',
      instructions: const [],
      secondaryMuscles: const [],
    );
  }
}

class WorkoutSet {
  String id;
  double? weight;
  int? reps;
  bool isCompleted;

  WorkoutSet({required this.id, this.weight, this.reps, this.isCompleted = false});

  Map<String, dynamic> toMap() {
    return {'id': id, 'weight': weight ?? 0.0, 'reps': reps ?? 0, 'isCompleted': isCompleted};
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] ?? '',
      weight: (map['weight'] as num?)?.toDouble(),
      reps: map['reps'] as int?,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class WorkoutExercise {
  final Exercise exercise;
  List<WorkoutSet> sets;

  WorkoutExercise({required this.exercise, required this.sets});

  // CLEANED DB PAYLOAD: Excludes copyrighted text, summaries, and image URLs
  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exercise.id,
      'name': exercise.name,
      'targetMuscle': exercise.targetMuscle,
      'equipment': exercise.equipment,
      'category': exercise.category,
      'bodyParts': exercise.bodyParts,
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exercise: Exercise.fromMap(map),
      sets: (map['sets'] as List<dynamic>? ?? [])
          .map((s) => WorkoutSet.fromMap(s))
          .toList(),
    );
  }
}

class WorkoutLog {
  String? id;
  String userId;
  DateTime startTime;
  DateTime? endTime;
  List<WorkoutExercise> exercises;

  WorkoutLog({this.id, required this.userId, required this.startTime, this.endTime, required this.exercises});

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map, String docId) {
    return WorkoutLog(
      id: docId,
      userId: map['userId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      exercises: (map['exercises'] as List<dynamic>? ?? [])
          .map((e) => WorkoutExercise.fromMap(e))
          .toList(),
    );
  }
}