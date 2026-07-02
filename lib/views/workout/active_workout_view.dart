// lib/views/workout/active_workout_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/workout_models.dart';
import '../../models/workout_plan_model.dart'; 
import '../exercise/exercise_search_view.dart';
import 'widgets/exercise_card.dart';
import 'widgets/workout_stats_header.dart';
import '../../services/exercise_service.dart'; 

import '../../controllers/workout/workout_controller.dart';
import '../../controllers/workout/workout_timer_controller.dart';
import '../../controllers/history/workout_history_controller.dart';
import '../../controllers/workout/workout_questionnaire_controller.dart';

class ActiveWorkoutView extends StatefulWidget {
  final WorkoutLog? editingLog; 
  final List<RoutineExercise>? initialExercises;

  const ActiveWorkoutView({
    super.key, 
    this.editingLog,
    this.initialExercises,
  });

  @override
  State<ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends State<ActiveWorkoutView> {
  bool _isHydratingApiData = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final workoutCtrl = context.read<WorkoutController>();
      final timerCtrl = context.read<WorkoutTimerController>();

      if (widget.editingLog != null) {
        workoutCtrl.loadWorkoutForEditing(widget.editingLog!);
        timerCtrl.loadExistingDuration(
          widget.editingLog!.startTime, 
          widget.editingLog!.endTime
        );
      } else {
        workoutCtrl.startNewWorkout(initialExercises: widget.initialExercises);
        timerCtrl.startTimer();

        // 🟢 API HYDRATION PATHWAY
        if (widget.initialExercises != null && widget.initialExercises!.isNotEmpty) {
          setState(() => _isHydratingApiData = true);
          print("📡 Active Session: Hydrating routine templates via WorkoutX API...");

          try {
            final exerciseService = ExerciseService(); 
            
            for (int i = 0; i < workoutCtrl.activeExercises.length; i++) {
              final activeWorkoutExercise = workoutCtrl.activeExercises[i];
              final String rawId = activeWorkoutExercise.exercise.id.trim(); // Reads pure 4-digit ID from updated controller
              
              if (rawId.isNotEmpty) {
                final Exercise? liveExerciseSpecs = await exerciseService.fetchExerciseById(rawId);
                
                if (liveExerciseSpecs != null) {
                  setState(() {
                    workoutCtrl.activeExercises[i] = WorkoutExercise(
                      exercise: liveExerciseSpecs,
                      sets: activeWorkoutExercise.sets, 
                    );
                  });
                }
              }
            }
            print("🎯 Active Session Hydration complete. Real-time media elements rendered.");
          } catch (e) {
            print("⚠️ Session Hydration warning: $e. Fallback local cached data retained.");
          } finally {
            setState(() => _isHydratingApiData = false);
          }
        }
      }
    });
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final workoutCtrl = context.watch<WorkoutController>();
    final timerCtrl = context.watch<WorkoutTimerController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leadingWidth: widget.editingLog != null ? 80 : 56, // 🟢 NEW: Expands width to fit the text
        leading: widget.editingLog != null
            ? TextButton(
                onPressed: () => Navigator.pop(context), // Safely backs out of the edit view
                child: const Text(
                  "Cancel", 
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)
                ),
              )
            : IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 28), 
                onPressed: () {}, // Keeps new workouts trapped safely
              ),
        title: const Text(
          "Log Workout", 
          style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)
        ),
        actions: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
             child: ElevatedButton(
               onPressed: _handleFinish, 
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.teal,
                 foregroundColor: Colors.white,
                 elevation: 0,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                 padding: const EdgeInsets.symmetric(horizontal: 20),
               ),
               child: Text(
                 widget.editingLog != null ? "Update" : "Finish", 
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
               ),
             ),
           )
        ],
      ),
      body: _isHydratingApiData 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text("Loading exercise media from API...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : Column(
              children: [
                WorkoutStatsHeader(
                  durationFormatted: _formatTime(timerCtrl.duration),
                  totalVolume: workoutCtrl.totalVolume.toInt(),
                  totalSets: workoutCtrl.totalSets,
                ),
                
                Expanded(
                  child: workoutCtrl.activeExercises.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24, top: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: workoutCtrl.activeExercises.length + 1,
                      itemBuilder: (context, index) {
                        if (index == workoutCtrl.activeExercises.length) {
                          return _buildAddExerciseButton();
                        }
                        
                        return ExerciseCard(
                          exerciseIndex: index,
                          exerciseData: workoutCtrl.activeExercises[index],
                          onRemoveExercise: () => workoutCtrl.removeExercise(index),
                          onAddSet: () => workoutCtrl.addSet(index),
                          onRemoveSet: (setIndex) => workoutCtrl.removeSet(index, setIndex),
                          onUpdateSet: (setIndex, {weight, reps, isCompleted}) {
                            workoutCtrl.updateSet(index, setIndex, weight: weight, reps: reps, isCompleted: isCompleted);
                          },
                        );
                      },
                    ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ]
                  ),
                  child: Row(
                    children: [
                       Expanded(
                         child: TextButton(
                            onPressed: () {
                             showDialog(
                               context: context,
                                builder: (dialogContext) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text("Discard Workout?", style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: const Text("Are you sure you want to discard this session? All progress will be lost."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext); // Close dialog
                                        context.read<WorkoutTimerController>().resetTimer();
                                        context.read<WorkoutController>().endWorkoutSession();
                                        Navigator.pop(context); // Exit active workout view
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
                                      child: const Text("Discard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                               ),
                             );
                           },
                           style: TextButton.styleFrom(
                             foregroundColor: Colors.redAccent,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                           ),
                           child: const Text("Discard Workout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         ),
                       ),
                    ],
                  ),
                )
              ],
            ),
    ); 
  }

  void _handleFinish() async {
    final workoutCtrl = context.read<WorkoutController>();
    final timerCtrl = context.read<WorkoutTimerController>();
    final historyCtrl = context.read<WorkoutHistoryController>();

    if (!workoutCtrl.validateWorkout()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Ensure all sets have valid weight and reps."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (widget.editingLog != null) {
      showDialog(
        context: context, 
        builder: (dialogContext) => AlertDialog( 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
          title: const Text("Update Workout?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to save changes to this history log?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text("Cancel", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); 
                await historyCtrl.updateWorkout(
                  logId: widget.editingLog!.id!,
                  exercises: workoutCtrl.activeExercises,
                  startTime: timerCtrl.startTime,
                  endTime: widget.editingLog!.endTime,
                );
                workoutCtrl.endWorkoutSession();
                timerCtrl.resetTimer();
                if (mounted) Navigator.pop(context); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, elevation: 0),
              child: const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Finish Workout?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Are you ready to complete and save this workout session?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Keep Going", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close the dialog
                
                await historyCtrl.saveNewWorkout(
                  exercises: workoutCtrl.activeExercises,
                  startTime: timerCtrl.startTime,
                );

                if (mounted) {
                  try {
                    context.read<WorkoutQuestionnaireController>().incrementWorkoutProgress();
                  } catch (_) {}

                  timerCtrl.resetTimer();
                  workoutCtrl.endWorkoutSession();
                  Navigator.pop(context, 1);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, elevation: 0),
              child: const Text("Finish & Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
            child: Icon(Icons.fitness_center, size: 48, color: Colors.teal.shade300),
          ),
          const SizedBox(height: 20),
          const Text("Ready to crush it?", style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text("Add an exercise to get started.", style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddExercise,
            icon: const Icon(Icons.add),
            label: const Text("Add Exercise", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: InkWell(
        onTap: _navigateToAddExercise,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                "Add Exercise",
                style: TextStyle(color: Colors.teal, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddExercise() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSearchView()),
    );
  }
}