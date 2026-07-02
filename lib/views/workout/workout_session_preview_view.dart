import 'package:flutter/material.dart';
import '../../models/workout_plan_model.dart';
import '../../utils/muscle_visuals.dart';
import 'active_workout_view.dart';
import '../../views/exercise/exercise_detail_view.dart';

class WorkoutSessionPreviewView extends StatelessWidget {
  final String dayTitle;
  final List<RoutineExercise> exercises;

  const WorkoutSessionPreviewView({
    Key? key,
    required this.dayTitle,
    required this.exercises,
  }) : super(key: key);

  /// Computes the distribution of muscle groups based on the volume of exercises given
  Map<String, double> _calculateMusclePercentages() {
    if (exercises.isEmpty) return {};
    
    final Map<String, int> counts = {};
    for (var exercise in exercises) {
      final muscle = exercise.targetGroup.trim().toLowerCase();
      counts[muscle] = (counts[muscle] ?? 0) + 1;
    }

    return counts.map((muscle, count) => MapEntry(muscle, count / exercises.length));
  }

  /// Safely formats the raw database string into the requested text layout
  String _formatPrescription(String? raw) {
    if (raw == null || raw.trim().isEmpty) return "Standard";
    
    if (raw.contains('*')) {
      final parts = raw.split('*');
      if (parts.length == 2) {
        return "${parts[0].trim()} sets ${parts[1].trim()} repetitions";
      }
    }
    return raw; // Fallback if the string doesn't contain an asterisk
  }


  @override
  Widget build(BuildContext context) {
    final muscleDistribution = _calculateMusclePercentages();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C24), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Workout Preview",
          style: TextStyle(color: Color(0xFF1A1C24), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.0)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0), // Padding to clear bottom button layout area
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- WORKOUT TITLE HEADER ---
                  Text(
                    dayTitle,
                    style: const TextStyle(color: Color(0xFF1A1C24), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 20),

                  // --- TARGET GROUPS & PERCENTAGES ---
                  const Text("Target Focus", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1C24))),
                  const SizedBox(height: 12),
                  _buildMuscleDistributionRow(muscleDistribution),
                  const SizedBox(height: 28),

                  // --- EXERCISE TRACKLIST TITLE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${exercises.length} Exercises",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      ),
                      Icon(Icons.assignment_rounded, size: 18, color: Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- EXERCISE ROW ITERATOR ---
                  _buildExercisesTracklist(context),
                ],
              ),
            ),
          ),

// --- 🟢 FIXED ACTION CONTROL ANCHOR ---
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4)),
                ],
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  // 🟢 FIX: Cleanly passes the template exercises down to the log tracker
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActiveWorkoutView(
                        initialExercises: exercises,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Start Workout",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleDistributionRow(Map<String, double> distribution) {
    if (distribution.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: distribution.entries.map((entry) {
        final visuals = MuscleVisuals.getVisuals(entry.key);
        final percentageString = "${(entry.value * 100).toStringAsFixed(0)}%";

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: visuals.backgroundColor, borderRadius: BorderRadius.circular(8)),
                child: Image.asset(visuals.imagePath),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1A1C24)),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    percentageString,
                    style: TextStyle(fontSize: 13, color: visuals.textColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExercisesTracklist(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final visuals = MuscleVisuals.getVisuals(exercise.targetGroup);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: visuals.backgroundColor, borderRadius: BorderRadius.circular(12)),
                child: Image.asset(visuals.imagePath),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1C24))),
                    const SizedBox(height: 2),
                    Text(
                      "Prescribed: ${_formatPrescription(exercise.prescribedSetsReps)}", // 🟢 FIXED: Calls the safe formatter
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // --- VERTICAL KEBAB MENU TRIGGER ---
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                onPressed: () => _showKebabOptionsSheet(context, exercise), // 🟢 FIXED: Passing the full exercise object
              ),
            ],
          ),
        );
      },
    );
  }

  void _showKebabOptionsSheet(BuildContext context, RoutineExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                exercise.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1C24)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF1F5F9)),
              
              // 🟢 The Single Action: View Details
              ListTile(
                leading: const Icon(Icons.visibility_outlined, color: Colors.blue),
                title: const Text("View Exercise Details", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () {
                  // 1. Close the bottom sheet first
                  Navigator.pop(sheetContext); 
                  
                  // 2. Route directly to the Exercise Detail View
                  // Note: Adjust the parameter name (exerciseId) if your detail view expects something slightly different!
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetailView(
                        exerciseId: exercise.exerciseId, 
                      ),
                    ),
                  );
                },
              ),
              
              // Pad the bottom slightly for modern device swipe bars
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}