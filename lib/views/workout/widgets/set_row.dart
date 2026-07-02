// lib/views/workout/widgets/set_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../models/workout_models.dart';
import 'input_cell.dart';

class SetRow extends StatelessWidget {
  final int setIndex;
  final WorkoutSet workoutSet;
  final VoidCallback onRemove;
  final Function(double?) onWeightChanged;
  final Function(int?) onRepsChanged;
  final VoidCallback onToggleCompletion;

  const SetRow({
    super.key,
    required this.setIndex,
    required this.workoutSet,
    required this.onRemove,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleCompletion,
  });

  @override
  Widget build(BuildContext context) {
    bool isDone = workoutSet.isCompleted;

    return Slidable(
      key: Key(workoutSet.id),
      direction: Axis.horizontal,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.20,
        children: [
          SlidableAction(
            onPressed: (context) {
              onRemove();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Set removed"), 
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
      child: Container(
        // Much softer tint for completed sets
        color: isDone ? Colors.teal.withOpacity(0.04) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 30, 
              child: Text(
                "${setIndex + 1}", 
                style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? Colors.teal : Colors.black87), 
                textAlign: TextAlign.center
              )
            ),
            const SizedBox(width: 60, child: Text("-", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
            
            // Weight Input
            Expanded(
              child: InputCell(
                hint: "0",
                value: (workoutSet.weight != null && workoutSet.weight! > 0) ? workoutSet.weight.toString() : null,
                allowDecimals: true,
                isCompleted: isDone,
                onChanged: (val) => onWeightChanged(double.tryParse(val)),
              )
            ),
            
            const SizedBox(width: 10),
            
            // Reps Input
            Expanded(
              child: InputCell(
                hint: "0",
                value: (workoutSet.reps != null && workoutSet.reps! > 0) ? workoutSet.reps.toString() : null,
                allowDecimals: false,
                isCompleted: isDone,
                onChanged: (val) => onRepsChanged(int.tryParse(val)),
              )
            ),
            
            const SizedBox(width: 10),
            
            // Checkbox (Modern Circle)
            GestureDetector(
              onTap: onToggleCompletion,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isDone ? Colors.teal : Colors.grey.shade200,
                  shape: BoxShape.circle, // Circular rather than square
                  boxShadow: isDone ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                ),
                child: Icon(Icons.check, size: 18, color: isDone ? Colors.white : Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}