import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout_models.dart';

class ExerciseService {
  // Global switch: True forces mock data immediately. False runs live API with auto-fallback.
  static const bool useMockData = false;

  // --- WORKOUTX API CREDENTIALS ---
  static const String apiKey = String.fromEnvironment('WORKOUTX_API_KEY');
  static const String _baseUrl = 'https://api.workoutxapp.com';

  // --- TRANSLATION LAYER MAP ---
  // Bridges custom Firestore template strings to exact WorkoutX API muscle targets
  final Map<String, String> _apiMuscleMapping = {
    'chest': 'pectorals',
    'back': 'lats',
    'upper legs': 'quads',
    'lower legs': 'calves',
    'shoulder': 'deltoids',
    'bicep': 'biceps',
    'triceps': 'triceps',
    'hamstrings': 'hamstrings',
  };

  // =====================================================================
  // 1. FETCH BY BODY PARTS (Crucial for Planned Workouts / Rule Engines)
  // =====================================================================
  Future<List<Exercise>> fetchByBodyParts(List<String> bodyParts) async {
    if (useMockData) return _mockExercises;

    // Translate incoming target tags into official API keywords
    List<String> translatedParts = bodyParts.map((part) {
      final lowercasePart = part.toLowerCase().trim();
      return _apiMuscleMapping[lowercasePart] ?? lowercasePart;
    }).toList();

    final String query = translatedParts.join(',');
    final url = Uri.parse('$_baseUrl/v1/exercises').replace(queryParameters: {
      'bodyPart': query,
      'limit': '10',
      'offset': '0',
    });

    try {
      final response = await http.get(url, headers: {'X-WorkoutX-Key': apiKey});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data.map((json) => Exercise.fromApiJson(json)).toList();
      }
      
      print("⚠️ fetchByBodyParts failed (Status: ${response.statusCode}). Using mock backup.");
      return _filterMockByBodyParts(translatedParts);
    } catch (e) {
      print("❌ Network error in fetchByBodyParts: $e. Using mock backup.");
      return _filterMockByBodyParts(translatedParts);
    }
  }

  // =====================================================================
  // 2. SEARCH & LIST EXERCISES (Crucial for Manual Free-Weight Tracking)
  // =====================================================================
  Future<ExerciseApiResponse> fetchExercises({
    String? query,
    int limit = 5,
    int offset = 0,
  }) async {
    if (useMockData) {
      return _getMockPagedResponse(query, limit, offset);
    }

    String endpointPath = (query != null && query.isNotEmpty) 
        ? '/v1/exercises/name/$query' 
        : '/v1/exercises';

    final url = Uri.parse('$_baseUrl$endpointPath').replace(queryParameters: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });

    try {
      final response = await http.get(url, headers: {'X-WorkoutX-Key': apiKey});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        final int total = jsonResponse['total'] ?? 0;

        final exercises = data.map((json) => Exercise.fromApiJson(json)).toList();
        return ExerciseApiResponse(
          exercises: exercises,
          nextOffset: offset + limit,
          hasNextPage: (offset + limit) < total,
        );
      }

      print("⚠️ fetchExercises failed (Status: ${response.statusCode}). Defaulting to mock catalog search.");
      return _getMockPagedResponse(query, limit, offset);
    } catch (e) {
      print("❌ Network connection failed in fetchExercises. Defaulting to mock catalog search.");
      return _getMockPagedResponse(query, limit, offset);
    }
  }

  // =====================================================================
  // 3. FETCH SINGLE EXERCISE BY ID (Crucial for displaying details on Start Workout)
  // =====================================================================
  Future<Exercise?> fetchExerciseById(String exerciseId) async {
    if (useMockData) return _lookupMockExercise(exerciseId);

    // 🟢 FIX 1: Automatically pad the incoming string with leading zeros to guarantee 4 digits
    // Example: "43" -> "0043" | "576" -> "0576"
    final String standardizedId = exerciseId.trim().padLeft(4, '0');

    // 🟢 FIX 2: Ensure correct URL path matching the WorkoutX documentation exactly
    final url = Uri.parse('$_baseUrl/v1/exercises/exercise/$standardizedId');

    print("📡 Hydration API Request: Contacting live endpoint for ID [$standardizedId]...");

    try {
      final response = await http.get(
        url, 
        headers: {
          'X-WorkoutX-Key': apiKey,
          'Content-Type': 'application/json',
        }
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Handle payload normalization if the server wraps single objects inside a 'data' map key
        final Map<String, dynamic> exerciseMap = jsonResponse['data'] != null 
            ? jsonResponse['data'] as Map<String, dynamic>
            : jsonResponse as Map<String, dynamic>;

        print("🎯 Hydration API Success: Data compiled for exercise ID [$standardizedId]");
        return Exercise.fromApiJson(exerciseMap);
      }

      print("⚠️ fetchExerciseById failed (Status: ${response.statusCode} for ID: $standardizedId). Redirecting to mock cache.");
      return _lookupMockExercise(standardizedId);
    } catch (e) {
      print("❌ Network timeout inside fetchExerciseById: $e. Redirecting to mock cache.");
      return _lookupMockExercise(standardizedId);
    }
  }

  // =====================================================================
  // PRIVATE LOCAL FALLBACK HANDLERS (The Safe Quota System)
  // =====================================================================
  Exercise? _lookupMockExercise(String exerciseId) {
    try {
      return _mockExercises.firstWhere((e) => e.id == exerciseId);
    } catch (_) {
      print("🚨 Critical Warning: ID $exerciseId is missing from local mock array cache.");
      return _mockExercises.first; // Absolute fallback to avoid view rendering crashes
    }
  }

  List<Exercise> _filterMockByBodyParts(List<String> translatedParts) {
    return _mockExercises.where((exercise) {
      return translatedParts.any((part) => 
          exercise.targetMuscle.toLowerCase() == part.toLowerCase());
    }).toList();
  }

  ExerciseApiResponse _getMockPagedResponse(String? query, int limit, int offset) {
    List<Exercise> filtered = _mockExercises;
    if (query != null && query.isNotEmpty) {
      filtered = _mockExercises.where((e) => e.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
    
    int end = (offset + limit) > filtered.length ? filtered.length : (offset + limit);
    List<Exercise> pagedList = offset >= filtered.length ? [] : filtered.sublist(offset, end);

    return ExerciseApiResponse(
      exercises: pagedList,
      nextOffset: end,
      hasNextPage: end < filtered.length,
    );
  }

  // =====================================================================
  // --- PRODUCTION-SYNCHRONIZED LOCAL ASSET CACHE ---
  // =====================================================================
  final List<Exercise> _mockExercises = [
    Exercise(
      id: '0576',
      name: 'Lever Chest Press',
      targetMuscle: 'Pectorals',
      equipment: 'Machine',
      imageUrl: 'https://s3assets.skimble.com/assets/2289478/image_iphone.jpg',
      instructions: ['Sit down back flat against pad', 'Grab handles, push forward smoothly', 'Return handles with control'],
    ),
    Exercise(
      id: '1760',
      name: 'Goblet Squat',
      targetMuscle: 'Quads',
      equipment: 'Dumbbell',
      imageUrl: 'https://i.pinimg.com/736x/8f/8c/a2/8f8ca24215b5445acd0e321f2c380352.jpg',
      instructions: ['Hold dumbbell close to chest', 'Squat down keeping weight in heels', 'Drive through legs to return upright'],
    ),
    Exercise(
      id: '0499',
      name: 'Inverted Row',
      targetMuscle: 'Lats',
      equipment: 'Bodyweight',
      imageUrl: 'https://i.pinimg.com/736x/08/b7/7f/08b77f1986408c2da2bf4163116963cf.jpg',
      instructions: ['Hang beneath a low bar or rings', 'Pull chest to bar keeping core rigid', 'Lower smoothly to starting hanging position'],
    ),
    Exercise(
      id: '0586',
      name: 'Lever Lying Leg Curl',
      targetMuscle: 'Hamstrings',
      equipment: 'Machine',
      imageUrl: 'https://s3assets.skimble.com/assets/2289478/image_iphone.jpg',
      instructions: ['Lie face down aligning knees with machine pivot axis', 'Curl pad toward glutes contracting hamstrings', 'Return leg arm down slowly'],
    ),
    Exercise(
      id: '0739',
      name: 'Sled 45 Leg Press',
      targetMuscle: 'Quads',
      equipment: 'Machine',
      imageUrl: 'https://i.pinimg.com/736x/8f/8c/a2/8f8ca24215b5445acd0e321f2c380352.jpg',
      instructions: ['Place feet mid-width on sled platform', 'Lower sled slowly breaking at hips and knees', 'Press platform away avoiding knee lockouts'],
    ),
    Exercise(
      id: '0314',
      name: 'Dumbbell Incline Bench Press',
      targetMuscle: 'Pectorals',
      equipment: 'Dumbbells',
      imageUrl: 'https://s3assets.skimble.com/assets/2289478/image_iphone.jpg',
      instructions: ['Press dumbbells up vertically from upper chest position', 'Lower dumbbells with elbows tucked at 45 degrees', 'Repeat execution path'],
    ),
    Exercise(
      id: '0017',
      name: 'Assisted Pull up',
      targetMuscle: 'Lats',
      equipment: 'Machine',
      imageUrl: 'https://i.pinimg.com/736x/08/b7/7f/08b77f1986408c2da2bf4163116963cf.jpg',
      instructions: ['Stand or kneel on support pad arm handles secure', 'Pull body upward until chin clears your hands level', 'Lower body down under complete muscular control'],
    ),
    Exercise(
      id: '0765',
      name: 'Smith Machine Shoulder Press',
      targetMuscle: 'Deltoids',
      equipment: 'Machine',
      imageUrl: 'https://s3assets.skimble.com/assets/2289478/image_iphone.jpg',
      instructions: ['Sit erect under tracked smith bar assembly', 'Lower bar directly down to collarbone line height path', 'Drive bar upward until arms lock softly over shoulders'],
    ),
    Exercise(
      id: '0285',
      name: 'Dumbbell Alternate Biceps Curl',
      targetMuscle: 'Biceps',
      equipment: 'Dumbbells',
      imageUrl: 'https://i.pinimg.com/736x/08/b7/7f/08b77f1986408c2da2bf4163116963cf.jpg',
      instructions: ['Hold dumbbells at side, supinate hand completely curling up', 'Squeeze bicep tissue apex peak at top contract zone', 'Return down slowly extending elbow lines fully'],
    )
  ];
}

class ExerciseApiResponse {
  final List<Exercise> exercises;
  final int nextOffset;
  final bool hasNextPage;

  ExerciseApiResponse({
    required this.exercises,
    required this.nextOffset,
    required this.hasNextPage,
  });
}