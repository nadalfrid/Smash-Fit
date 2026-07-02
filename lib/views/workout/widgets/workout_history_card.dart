// lib/views/workout/widgets/workout_history_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; 

import '../../../models/workout_models.dart';
import '../../../controllers/history/workout_history_controller.dart'; 
import '../active_workout_view.dart';

class WorkoutHistoryCard extends StatelessWidget {
  final WorkoutLog log;

  const WorkoutHistoryCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final int exerciseCount = log.exercises.length;
    final int setCount = log.exercises.fold(0, (sum, ex) => sum + ex.sets.length);
    final String duration = log.endTime != null 
        ? "${log.endTime!.difference(log.startTime).inMinutes}m" 
        : "Incomplete";
    
    String previewText = log.exercises.take(3).map((e) => e.exercise.name).join(", ");
    if (log.exercises.length > 3) previewText += ", +${log.exercises.length - 3}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Upgraded to match Smash Fit 24dp design guidelines
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 20, 
            offset: const Offset(0, 6)
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(log.startTime).toUpperCase(),
                    style: const TextStyle(color: Color(0xFF2A9D8F), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy').format(log.startTime), 
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF233036))
                  ),
                ],
              ),
              
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF8B8B8B)), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: Colors.white,
                elevation: 4,
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ActiveWorkoutView(editingLog: log)),
                    );
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, log);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit', 
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: Colors.blue, size: 22), 
                        SizedBox(width: 10), 
                        Text("Edit Workout", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF233036), fontSize: 14))
                      ]
                    )
                  ),
                  const PopupMenuItem(
                    value: 'delete', 
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22), 
                        SizedBox(width: 10), 
                        Text("Delete Log", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF233036), fontSize: 14))
                      ]
                    )
                  ),
                ],
              )
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Row containing horizontally stacked metrics pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatPill(Icons.timer_outlined, duration, Colors.orange),
              _buildStatPill(Icons.fitness_center_rounded, "$exerciseCount Exercises", Colors.teal),
              _buildStatPill(Icons.repeat, "$setCount Sets", Colors.blue),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            previewText, 
            style: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500), 
            maxLines: 2, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50.withAlpha(180),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 5),
          Text(
            text, 
            style: TextStyle(color: color.shade800, fontSize: 11, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WorkoutLog currentLog) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
          title: const Text("Delete Workout?", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF233036))),
          content: const Text("Are you sure you want to delete this workout history? This action cannot be undone.", style: TextStyle(color: Color(0xFF8B8B8B), fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF8B8B8B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); 
                try {
                  await context.read<WorkoutHistoryController>().deleteWorkout(currentLog.id!);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Workout deleted successfully", style: TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: ${e.toString()}"),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE63946),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}