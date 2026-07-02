// lib/views/exercise/exercise_search_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercise_detail_view.dart';

import '../../controllers/workout/workout_controller.dart';
import '../../controllers/exercise/exercise_search_controller.dart';

// Import the visual mapper
import '../../utils/muscle_visuals.dart';

class ExerciseSearchView extends StatefulWidget {
  const ExerciseSearchView({super.key});

  @override
  State<ExerciseSearchView> createState() => _ExerciseSearchViewState();
}

class _ExerciseSearchViewState extends State<ExerciseSearchView> {
  late ScrollController _scrollController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ExerciseSearchController>().searchExercises(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchCtrl = context.watch<ExerciseSearchController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            context.read<ExerciseSearchController>().clearSelection();
            Navigator.pop(context);
          },
          child: const Text("Cancel", style: TextStyle(color: Colors.teal, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: const Text("Add Exercise",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.black),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search exercise",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: Colors.grey.shade100,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          Expanded(
            child: Builder(
              builder: (context) {
                if (searchCtrl.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }

                if (searchCtrl.searchResults.isEmpty) {
                  if (!searchCtrl.hasSearched) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 64, color: Colors.grey.shade200),
                          const SizedBox(height: 16),
                          Text("Type an exercise name to search", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return const Center(
                    child: Text(
                      "No exercises found.\nTry another keyword like chest, back…",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: searchCtrl.searchResults.length + 1,
                  itemBuilder: (context, index) {
                    if (index == searchCtrl.searchResults.length) {
                      if (!searchCtrl.hasNextPage) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: searchCtrl.isLoadingMore
                              ? const CircularProgressIndicator(color: Colors.teal)
                              : OutlinedButton(
                                  onPressed: () {
                                    context.read<ExerciseSearchController>().loadMoreExercises();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                    side: const BorderSide(color: Colors.teal),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: const Text("Load More Exercises", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                        ),
                      );
                    }

                    final exercise = searchCtrl.searchResults[index];
                    final isSelected = searchCtrl.selectedExercises.contains(exercise);
                    
                    // Grab the visuals based on the target muscle
                    final visuals = MuscleVisuals.getVisuals(exercise.targetMuscle);

                    return InkWell(
                      onTap: () {
                        if (exercise.id.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseDetailView(exerciseId: exercise.id),
                            ),
                          );
                        }
                      },
                      child: Container(
                        color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 70,
                              color: isSelected ? Colors.teal : Colors.transparent,
                            ),
                            
                            // The Clean Hybrid Avatar Container
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: visuals.backgroundColor, // Matches the muscle group
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: _buildMuscleAvatar(visuals), // Call the foolproof helper method
                                ),
                              ),
                            ),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exercise.name,
                                      style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  
                                  // Colored Typography
                                  Text(
                                    exercise.targetMuscle.toUpperCase(),
                                    style: TextStyle(
                                      color: visuals.textColor, // Colored to match the PNG!
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.read<ExerciseSearchController>().toggleExerciseSelection(exercise),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Icon(
                                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                                  color: isSelected ? Colors.teal : Colors.grey,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Bottom Bar for Adding Exercises
          if (searchCtrl.selectedExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final workoutCtrl = context.read<WorkoutController>();
                    final searchCtrl = context.read<ExerciseSearchController>();
                    workoutCtrl.addExercisesFromSearch(searchCtrl.selectedExercises);
                    searchCtrl.clearSelection();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                      "Add ${searchCtrl.selectedExercises.length} exercise${searchCtrl.selectedExercises.length > 1 ? 's' : ''}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

// --- UI HELPER: FOOLPROOF PNG AVATAR ---
  Widget _buildMuscleAvatar(MuscleVisuals visuals) {
    return Image.asset(
      visuals.imagePath,
      fit: BoxFit.contain,
      // If a PNG file is accidentally deleted or spelled wrong in pubspec.yaml, 
      // it won't crash the app. It will just safely show a colored dumbbell.
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.fitness_center, 
          color: visuals.textColor, 
          size: 26,
        );
      },
    );
  }
}