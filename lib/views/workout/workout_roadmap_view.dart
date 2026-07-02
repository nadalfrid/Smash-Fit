// lib/views/workout/workout_roadmap_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_plan_model.dart';
import '../../controllers/workout/workout_questionnaire_controller.dart';
import 'workout_session_preview_view.dart';
import '../main_layout.dart';

// REMOVED: 'workout_questionnaire_view.dart' import deleted since routing logic handles this in the controller now!

class WorkoutRoadmapView extends StatelessWidget {
  final WorkoutPlan plan;
  final int totalWeeks;
  final int daysPerWeek;

  const WorkoutRoadmapView({
    Key? key,
    required this.plan,
    required this.totalWeeks,
    required this.daysPerWeek,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- STATE RECOGNITION BOUNDARY ---
    return Consumer<WorkoutQuestionnaireController>(
      builder: (context, trackingCtrl, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(color: Color(0xFF1A1C24), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$totalWeeks Weeks • $daysPerWeek Days per Week",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 1.0),
            ),
leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF1A1C24)),
              onPressed: () {
                // --- 🟢 FIX: ABSOLUTE SHELL ROOT REDIRECT ---
                // Pushes the main layout framework shell so your bottom nav tabs return!
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainLayout()), // 🧠 Changed from WorkoutView to MainLayout
                  (route) => false, // Completely wipes out the questionnaire path history
                );
              },
            ),
            // --- TOP-RIGHT SETTINGS DROPDOWN ACCENT ---
            actions: [
              PopupMenuButton<String>(
  icon: const Icon(Icons.settings_outlined, color: Colors.black87),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  onSelected: (value) {
    if (value == 'delete') {
      // 🟢 NEW: Confirmation Dialog for Deleting the Plan
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Delete Plan?", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)
          ),
          content: const Text(
            "Are you sure you want to permanently delete your current workout plan? You will need to take the questionnaire again to generate a new one."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                
                // Call the new cloud wipe function
                final success = await context.read<WorkoutQuestionnaireController>().deleteActivePlanFromCloud();
                
                if (success && context.mounted) {
                  // Route the user back to the home/dashboard view after deletion
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
              child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  },
  itemBuilder: (context) => [
    // 🟢 TASK 1 FIX: Manage Plan is removed. Only Delete Plan remains for a cleaner UI.
    const PopupMenuItem(
      value: 'delete',
      child: Row(
        children: [
          Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          SizedBox(width: 10),
          Text("Delete Plan", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  ],
),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: RoadmapLinePainter(totalNodes: totalWeeks * daysPerWeek),
                ),
              ),
              ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                itemCount: totalWeeks,
                itemBuilder: (context, weekIndex) {
                  return _buildWeekSection(context, weekIndex, trackingCtrl);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekSection(BuildContext context, int weekIndex, WorkoutQuestionnaireController trackingCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "WEEK ${weekIndex + 1}",
              style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
            ),
          ),
        ),
        ...List.generate(daysPerWeek, (dayIndex) {
          final int overallNodeNumber = (weekIndex * daysPerWeek) + dayIndex + 1;
          final int templateDayIndex = dayIndex % (plan.weeklyRoutine?.length ?? 1);
          final WorkoutDay currentDayTemplate = plan.weeklyRoutine![templateDayIndex];
          
          final int zeroBasedNodeIndex = overallNodeNumber - 1;
          
          final bool isCompleted = zeroBasedNodeIndex < trackingCtrl.currentDayIndex;
          final bool isActive = zeroBasedNodeIndex == trackingCtrl.currentDayIndex;
          final bool isLocked = zeroBasedNodeIndex > trackingCtrl.currentDayIndex;

          return _buildRoadmapNode(
            context: context,
            nodeNumber: overallNodeNumber,
            dayTitle: currentDayTemplate.dayName,
            isCompleted: isCompleted,
            isActive: isActive,
            isLocked: isLocked,
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildRoadmapNode({
    required BuildContext context,
    required int nodeNumber,
    required String dayTitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLocked,
  }) {
    Alignment nodeAlignment = Alignment.center;
    if (nodeNumber % 3 == 1) {
      nodeAlignment = Alignment.centerLeft;
    } else if (nodeNumber % 3 == 0) {
      nodeAlignment = Alignment.centerRight;
    }

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    IconData tailIcon = Icons.lock_outline_rounded;
    Color tailIconColor = Colors.grey.shade300;

    if (isCompleted) {
      cardColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      tailIcon = Icons.check_circle_rounded;
      tailIconColor = Colors.green.shade500;
    } else if (isActive) {
      cardColor = Colors.purple.shade600;
      borderColor = Colors.purple.shade400;
      tailIcon = Icons.play_arrow_rounded;
      tailIconColor = Colors.white;
    }

    return Align(
      alignment: nodeAlignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: GestureDetector(
          // FIXED: Swapped out the accidental trailing semicolon with a proper comma separator
          onTap: !isLocked ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutSessionPreviewView(
                  dayTitle: dayTitle,
                  exercises: plan.weeklyRoutine!.firstWhere((day) => day.dayName == dayTitle, orElse: () => plan.weeklyRoutine!.first).exercises,
                ),
              ),
            );
          } : null, 
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isLocked ? 0.5 : 1.0, 
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: MediaQuery.of(context).size.width * 0.70,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive ? Colors.purple.withOpacity(0.2) : Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? Colors.white.withOpacity(0.2) 
                          : (isCompleted ? Colors.green.withOpacity(0.15) : Colors.grey.shade100),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "$nodeNumber",
                        style: TextStyle(
                          color: isActive 
                              ? Colors.white 
                              : (isCompleted ? Colors.green.shade700 : Colors.grey.shade600),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCompleted ? "COMPLETED" : "Workout $nodeNumber",
                          style: TextStyle(
                            color: isActive 
                                ? Colors.white70 
                                : (isCompleted ? Colors.green.shade600 : Colors.grey.shade400),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: isCompleted ? 0.5 : 0.0,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          dayTitle,
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF1A1C24),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    tailIcon,
                    color: tailIconColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoadmapLinePainter extends CustomPainter {
  final int totalNodes;
  RoadmapLinePainter({required this.totalNodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.shade100.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.5, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}