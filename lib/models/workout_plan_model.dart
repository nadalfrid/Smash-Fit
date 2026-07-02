class RoutineExercise {
  final String name;
  final String targetGroup;      // e.g., "upper legs", "chest", "back"
  final String prescribedSetsReps; // e.g., "3*8-10", "2*6-8"
  final String exerciseId;       // 🟢 Added to map WorkoutX unique identifiers

  RoutineExercise({
    required this.name,
    required this.targetGroup,
    required this.prescribedSetsReps,
    required this.exerciseId, 
  });

  // 🟢 Translates exercise map fields from Firestore
  factory RoutineExercise.fromMap(Map<String, dynamic> map) {
    return RoutineExercise(
      name: map['name'] ?? '',
      targetGroup: map['targetGroup'] ?? '',
      prescribedSetsReps: map['prescribedSetsReps'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
    );
  }
}

class WorkoutDay {
  final String dayName; 
  final List<RoutineExercise> exercises;

  WorkoutDay({
    required this.dayName,
    required this.exercises,
  });

  // 🟢 Translates day routine map fields from Firestore
  factory WorkoutDay.fromMap(Map<String, dynamic> map) {
    var rawExercises = map['exercises'] as List<dynamic>? ?? [];
    List<RoutineExercise> parsedExercises = rawExercises
        .map((ex) => RoutineExercise.fromMap(ex as Map<String, dynamic>))
        .toList();

    return WorkoutDay(
      dayName: map['dayName'] ?? '',
      exercises: parsedExercises,
    );
  }
}

class WorkoutPlan {
  final String id;
  final String title;
  final String goal;
  final String difficulty;
  final String durationText; 
  final String shortDescription;
  final String fullDescription;
  final List<String> suggestedEquipment;
  final List<String> commonExercises;
  final List<WorkoutDay>? weeklyRoutine; 

  WorkoutPlan({
    required this.id,
    required this.title,
    required this.goal,
    required this.difficulty,
    required this.durationText,
    required this.shortDescription,
    required this.fullDescription,
    required this.suggestedEquipment,
    required this.commonExercises,
    this.weeklyRoutine,
  });

  // 🟢 Top-level Firestore map deserialization engine
  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    List<String> equipment = List<String>.from(map['suggestedEquipment'] ?? []);
    List<String> commonEx = List<String>.from(map['commonExercises'] ?? []);

    List<WorkoutDay>? routine;
    if (map['weeklyRoutine'] != null) {
      var rawRoutine = map['weeklyRoutine'] as List<dynamic>;
      routine = rawRoutine
          .map((day) => WorkoutDay.fromMap(day as Map<String, dynamic>))
          .toList();
    }

    return WorkoutPlan(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      goal: map['goal'] ?? '',
      difficulty: map['difficulty'] ?? '',
      durationText: map['durationText'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      fullDescription: map['fullDescription'] ?? '',
      suggestedEquipment: equipment,
      commonExercises: commonEx,
      weeklyRoutine: routine,
    );
  }

  // --- Getters remain completely unchanged ---
  int get totalWeeks {
    try {
      final firstToken = durationText.split(' ').first;
      return int.tryParse(firstToken) ?? 4; 
    } catch (_) {
      return 4; 
    }
  }

  int get daysPerWeek => weeklyRoutine?.length ?? 3; 
}