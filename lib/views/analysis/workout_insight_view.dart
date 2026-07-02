// lib/views/analysis/workout_insight_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/analysis/workout_insight_controller.dart';
import '../../controllers/history/workout_history_controller.dart'; 
import '../../models/workout_insight_model.dart'; // Ensure this points to your micro models path
import 'widgets/calendar_filter_popover.dart'; 

class WorkoutInsightView extends StatefulWidget {
  final WorkoutHistoryController sharedWorkoutController; 

  const WorkoutInsightView({
    super.key,
    required this.sharedWorkoutController,
  });

  @override
  State<WorkoutInsightView> createState() => _WorkoutInsightViewState();
}

class _WorkoutInsightViewState extends State<WorkoutInsightView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize layout data using the unfiltered streaming cache pool
      context.read<WorkoutInsightController>().fetchAndCompileTimelineWindow(widget.sharedWorkoutController);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WorkoutInsightController>();
    const Color smashFitPurple = Color(0xFF8B1FA9);

    // 🟢 REACTIVE BOUNDS HOOK: Watches for background stream completion changes.
    // Automatically compiles insights the moment logs finish downloading from Firestore.
    final currentHistoryLogsPool = widget.sharedWorkoutController.allLogs;
    if (controller.loggedWorkoutDates.isEmpty && currentHistoryLogsPool.isNotEmpty && !controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchAndCompileTimelineWindow(widget.sharedWorkoutController);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIMELINE CONTROLS FILTER CARD
          GestureDetector(
            onTap: () {
              CalendarFilterPopover.show(
                context: context,
                initialStartDate: controller.startDate,
                initialEndDate: controller.endDate,
                onDatesSelected: (newStart, newEnd) {
                  controller.updateDateRange(newStart, newEnd, widget.sharedWorkoutController);
                },
              );
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_outlined, color: smashFitPurple, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${controller.startDate.day}/${controller.startDate.month}/${controller.startDate.year} - ${controller.endDate.day}/${controller.endDate.month}/${controller.endDate.year}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        const Text("Active filter scope. Tap to select custom date window.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.tune_outlined, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),

          // 2. ACTIVE LOGGED DAYS TIMELINE RIBBON STRIP
          if (controller.loggedWorkoutDates.isNotEmpty)
            Container(
              height: 64,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: controller.loggedWorkoutDates.length,
                itemBuilder: (context, index) {
                  final dayDate = controller.loggedWorkoutDates[index];
                  final bool isSelected = controller.selectedActiveDate != null && 
                      DateUtils.isSameDay(dayDate, controller.selectedActiveDate!);

                  return GestureDetector(
                    // 🟢 FIXED: Passes your unfiltered 'allLogs' down to fuel the selection method safely
                    onTap: () => controller.selectActiveDate(dayDate, widget.sharedWorkoutController.allLogs),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 58,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? smashFitPurple : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                        boxShadow: isSelected ? [
                          BoxShadow(color: smashFitPurple.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getShortWeekday(dayDate.weekday),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${dayDate.day}",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // 3. MAIN WORKOUT CASCADE FEED LIST SHEET WORKSPACE
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator(color: smashFitPurple))
                : controller.dailySessionsInsights.isEmpty
                    ? _buildEmptyStateView()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
                        // 🟢 CASCADING MULTI-LOG REFACTOR: Loops through total count of daily logs dynamically
                        itemCount: controller.dailySessionsInsights.length,
                        itemBuilder: (context, sessionIdx) {
                          final insight = controller.dailySessionsInsights[sessionIdx];
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSessionMasterHeader(insight.workoutTitle),
                              ...insight.exercisesData.map((group) => _buildExerciseAuditCard(group)).toList(),
                              const SizedBox(height: 24), // Spacing cushion separate blocks cleanly
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionMasterHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B1070), Color(0xFF8B1FA9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("LOGGED WORKOUT SESSION", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(title.toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseAuditCard(ExerciseInsightGroup movementGroup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              movementGroup.exerciseName.toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.3),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: movementGroup.analyzedSets.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, sIdx) {
              final setRecord = movementGroup.analyzedSets[sIdx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        "SET ${setRecord.setNumber}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ),
                    Icon(setRecord.statusIconMarker, color: setRecord.themeColor, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            setRecord.badgeTitle.toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.w900, color: setRecord.themeColor, fontSize: 12, letterSpacing: 0.2),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            setRecord.explanation,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${setRecord.weight.toStringAsFixed(1).replaceAll('.0', '')}kg x ${setRecord.reps}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.analytics_outlined, color: Color(0xFF8B1FA9), size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "VOLUME AUDIT: ${movementGroup.totalExerciseVolume} KG LOGGED",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        movementGroup.volumeFeedbackString,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _getShortWeekday(int weekday) {
    switch (weekday) {
      case 1: return "MON"; case 2: return "TUE"; case 3: return "WED";
      case 4: return "THU"; case 5: return "FRI"; case 6: return "SAT";
      default: return "SUN";
    }
  }

  Widget _buildEmptyStateView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_outlined, color: Color(0xFFCBD5E1), size: 36),
          SizedBox(height: 10),
          Text("No workout logs captured inside this filter range.", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }
}