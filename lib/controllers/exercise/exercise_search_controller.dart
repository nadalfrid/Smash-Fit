import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/workout_models.dart';
import '../../services/exercise_service.dart';

class ExerciseSearchController extends ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();
  
  List<Exercise> searchResults = [];
  List<Exercise> selectedExercises = [];

  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasNextPage = false;
  bool hasSearched = false;
  
  int _currentOffset = 0;
  String _currentQuery = '';
  Timer? _searchDebounce;

Future<void> loadExercises() async {
  searchResults.clear();
  selectedExercises.clear();
  _currentOffset = 0; // FIXED HERE
  _currentQuery = '';
  await _fetchExercises(reset: true);
}

void searchExercises(String query) {
    _currentQuery = query;

    _searchDebounce?.cancel();

    // 💥 GUARD: If the search bar is empty, clear results and DO NOT fetch!
    if (query.trim().isEmpty) {
      searchResults.clear();
      hasSearched = false; // Reset search state
      notifyListeners();
      return; 
    }

    hasSearched = true;

    // Wait 800ms after they stop typing before spending an API credit
    _searchDebounce = Timer(const Duration(milliseconds: 800), () async {
      searchResults.clear();
      _currentOffset = 0; 
      await _fetchExercises(reset: true);
    });
  }

  Future<void> loadMoreExercises() async {
    // 💥 THE GATEKEEPER: If we are already loading, or there are no more pages, STOP!
    if (isLoading || isLoadingMore || !hasNextPage) {
      return; 
    }

    // Lock the gate immediately
    isLoadingMore = true;
    notifyListeners(); 

    // Fetch the next batch
    await _fetchExercises();

    // Unlock the gate when finished
    isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _fetchExercises({bool reset = false}) async {
    isLoading = true;
    notifyListeners();

    if (reset) _currentOffset = 0;

    final response = await _exerciseService.fetchExercises(
      query: _currentQuery.isEmpty ? null : _currentQuery,
      limit: 3, // Keep your current limit here
      offset: _currentOffset,
    );

    // 1. Add the new exercises to the list
    if (reset) {
      searchResults = response.exercises;
    } else {
      searchResults.addAll(response.exercises);
    }

    // 💥 2. NEW: Sort the list immediately after adding the new data!
    _sortSearchResultsByRelevance(_currentQuery);

    // 3. Update pagination states
    _currentOffset = response.nextOffset;
    hasNextPage = response.hasNextPage;

    isLoading = false;
    notifyListeners();
  }

  void toggleExerciseSelection(Exercise exercise) {
    if (selectedExercises.contains(exercise)) {
      selectedExercises.remove(exercise);
    } else {
      selectedExercises.add(exercise);
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedExercises.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // --- RELEVANCE SORTING ALGORITHM ---
  void _sortSearchResultsByRelevance(String query) {
    if (query.trim().isEmpty || searchResults.isEmpty) return;
    
    final q = query.trim().toLowerCase();

    searchResults.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      // 1. EXACT MATCH WINS ABSOLUTELY (e.g., "Squat" == "Squat")
      if (aName == q && bName != q) return -1;
      if (bName == q && aName != q) return 1;

      // 2. STARTS WITH WINS SECOND (e.g., "Squat" prioritizes "Squat Jump" over "Hack Squat")
      final aStarts = aName.startsWith(q);
      final bStarts = bName.startsWith(q);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      // 3. EXACT WORD MATCH WINS THIRD (e.g., "Press" prioritizes "Bench Press" over "Depressor")
      // We split by spaces to check for exact standalone words.
      final aHasWord = aName.split(RegExp(r'\s+')).contains(q);
      final bHasWord = bName.split(RegExp(r'\s+')).contains(q);
      if (aHasWord && !bHasWord) return -1;
      if (bHasWord && !aHasWord) return 1;

      // 4. FALLBACK: Alphabetical order for everything else
      return aName.compareTo(bName);
    });
  }
}