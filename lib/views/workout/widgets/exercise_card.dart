// lib/views/workout/widgets/exercise_card.dart
import 'package:flutter/material.dart';
import '../../../models/workout_models.dart';
import '../../exercise/exercise_detail_view.dart';
import 'set_row.dart';

// NEW: Import the visual mapper
import '../../../utils/muscle_visuals.dart';

class ExerciseCard extends StatelessWidget {
  final int exerciseIndex;
  final WorkoutExercise exerciseData;
  final VoidCallback onRemoveExercise;
  final VoidCallback onAddSet;
  final Function(int) onRemoveSet;
  final Function(int, {double? weight, int? reps, bool? isCompleted}) onUpdateSet;

  const ExerciseCard({
    super.key,
    required this.exerciseIndex,
    required this.exerciseData,
    required this.onRemoveExercise,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
  });

  @override
  Widget build(BuildContext context) {
    // 💥 NEW: Grab the visuals based on the target muscle
    final visuals = MuscleVisuals.getVisuals(exerciseData.exercise.targetMuscle);

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Modern larger radius
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Name + Menu)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // 💥 NEW: The Clean PNG Avatar Container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: visuals.backgroundColor, 
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: _buildMuscleAvatar(visuals),
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      // 💥 NEW: Clean Typography matching the Search View
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exerciseData.exercise.name, 
                              style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              exerciseData.exercise.targetMuscle.toUpperCase(),
                              style: TextStyle(
                                color: visuals.textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'remove') {
                      onRemoveExercise();
                    } else if (val == 'details') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExerciseDetailView(exerciseId: exerciseData.exercise.id)),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'details', child: Row(children: [Icon(Icons.info_outline, color: Colors.blue, size: 20), SizedBox(width: 8), Text("View Details")])),
                    const PopupMenuItem(value: 'remove', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 8), Text("Remove Exercise", style: TextStyle(color: Colors.red))])),
                  ],
                )
              ],
            ),
          ),

          // Column Headers
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text("Set", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 60, child: Text("Prev", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text("kg", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text("Reps", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 40), 
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Sets
          ...exerciseData.sets.asMap().entries.map((entry) {
            int setIndex = entry.key;
            WorkoutSet set = entry.value;

            return SetRow(
              setIndex: setIndex,
              workoutSet: set,
              onRemove: () => onRemoveSet(setIndex),
              onWeightChanged: (weight) => onUpdateSet(setIndex, weight: weight),
              onRepsChanged: (reps) => onUpdateSet(setIndex, reps: reps),
              onToggleCompletion: () => onUpdateSet(setIndex, isCompleted: !set.isCompleted),
            );
          }),

          // Add Set Button (Modern Tinted Pill)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Center(
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Set", style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal,
                  backgroundColor: Colors.teal.withOpacity(0.08), // Soft tinted background
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
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
      // If a PNG file is missing, safely fallback to an icon without crashing
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.fitness_center, 
          color: visuals.textColor, 
          size: 24,
        );
      },
    );
  }
}