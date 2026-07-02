import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../controllers/history/workout_history_controller.dart';

class WorkoutCalendarPopup extends StatelessWidget {
  const WorkoutCalendarPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WorkoutHistoryController>();
    final today = DateTime.now();
    final todayMidnightCeiling = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final currentMonth = controller.focusedCalendarMonth;
    final int daysInMonth = DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);
    final int firstWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(20),
      content: SizedBox(
        width: 320, // Only width goes here
        child: Column(
          mainAxisSize: MainAxisSize.min, // Moved inside the Column!
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF233036)),
                  onPressed: () => controller.updateFocusedCalendarMonth(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF233036)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF233036)),
                  onPressed: () => controller.updateFocusedCalendarMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["M", "T", "W", "T", "F", "S", "S"].map((day) {
                return Text(
                  day,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B8B8B)),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: daysInMonth + firstWeekday - 1,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) {
                  return const SizedBox.shrink(); 
                }

                final int day = index - (firstWeekday - 1) + 1;
                final DateTime cellDate = DateTime(currentMonth.year, currentMonth.month, day);
                final bool isFuture = cellDate.isAfter(todayMidnightCeiling);
                
                final bool isSelected = cellDate.year == controller.tempSelectedDate.year &&
                                        cellDate.month == controller.tempSelectedDate.month &&
                                        cellDate.day == controller.tempSelectedDate.day;

                final String dotKey = "${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";
                final bool hasWorkout = controller.datesWithWorkouts.contains(dotKey);

                return GestureDetector(
                  onTap: isFuture ? null : () => controller.setTempSelectedDate(cellDate),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2A9D8F) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Opacity(
                      opacity: isFuture ? 0.3 : 1.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$day",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF233036),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 4,
                            width: 4,
                            decoration: BoxDecoration(
                              color: hasWorkout 
                                  ? (isSelected ? Colors.white : const Color(0xFF2A9D8F)) 
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Color(0xFF8B8B8B), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.confirmCalendarSelection();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A9D8F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}