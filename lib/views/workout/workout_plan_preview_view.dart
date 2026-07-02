import 'package:flutter/material.dart';
import '../../models/workout_plan_model.dart';
import '../../utils/muscle_visuals.dart';
import '../../utils/equipment_visuals.dart';
import 'package:provider/provider.dart';
import 'workout_roadmap_view.dart';
import '../../controllers/workout/workout_questionnaire_controller.dart';

class WorkoutPlanPreviewView extends StatelessWidget {
  final WorkoutPlan plan;

  const WorkoutPlanPreviewView({Key? key, required this.plan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          "Plan Details",
          style: TextStyle(color: Color(0xFF1A1C24), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.0)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 100.0), // Extra bottom padding for floating button area
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER INFO ---
                  Text(
                    plan.title,
                    style: const TextStyle(color: Color(0xFF1A1C24), fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Goal: ${plan.goal}",
                    style: TextStyle(color: Colors.purple.shade600, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // --- PREMIUM METRIC CHIPS ---
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMetricChip(Icons.speed_rounded, plan.difficulty, Colors.blue.shade50, Colors.blue.shade700),
                      _buildMetricChip(Icons.timer_rounded, plan.durationText.split('•').last.trim(), Colors.orange.shade50, Colors.orange.shade700),
                      _buildMetricChip(Icons.calendar_today_rounded, "${plan.daysPerWeek} Sessions/Week", Colors.green.shade50, Colors.green.shade700),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Target Focus Group Layout
                  Wrap(
                    spacing: 6,
                    children: plan.commonExercises.map((focus) {
                      return Chip(
                        label: Text(focus, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(color: Colors.grey.shade700),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // --- FULL DESCRIPTION ---
                  const Text("About the Program", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C24))),
                  const SizedBox(height: 8),
                  Text(
                    plan.fullDescription,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 28),

                  // --- SUGGESTED EQUIPMENT GRID ---
                  const Text("Required Equipment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C24))),
                  const SizedBox(height: 12),
                  _buildEquipmentSection(),
                  const SizedBox(height: 28),

                  // --- COMMON EXERCISES PREVIEW ---
                  const Text("Common Exercises", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C24))),
                  const SizedBox(height: 12),
                  _buildExercisesList(),
                ],
              ),
            ),
          ),

          // --- BOTTOM FLOATING ACTION GATEWAY ---
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
                onPressed: () async {
                  // Read the configuration data inherited dynamically from our provider
                  final controller = Provider.of<WorkoutQuestionnaireController>(context, listen: false);
                  
                  final frequency = controller.selectedFrequency ?? "3 days / week";
                  final commitment = controller.selectedCommitment ?? "4 weeks";

                  int daysPerWeek = int.parse(frequency.substring(0, 1));
                  int weeksCount = int.parse(commitment.substring(0, 1));

                  await controller.saveUserSelectedPlanToCloud(plan);

                  // Forward the flow to the classic workout tracker screen seamlessly
                  if (context.mounted) { // Add mounted check for safety after async gap
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutRoadmapView(
                          plan: plan,
                          totalWeeks: weeksCount,
                          daysPerWeek: daysPerWeek,
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Select This Plan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    final equipmentList = plan.suggestedEquipment;
    if (equipmentList.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: equipmentList.map((item) {
        final icon = EquipmentVisuals.getIcon(item);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.purple.shade400),
              const SizedBox(width: 8),
              Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExercisesList() {
    final exercises = plan.weeklyRoutine?.first.exercises ?? [];
    if (exercises.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        // Pull design-matched styling configurations out from your custom logic mappings helper
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
              // Display image corresponding to muscle group with automated color backing styles
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: visuals.backgroundColor, borderRadius: BorderRadius.circular(12)),
                child: Image.asset(
                  visuals.imagePath,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.fitness_center, color: visuals.textColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1C24))),
                    const SizedBox(height: 2),
                    Text(
                      exercise.targetGroup.toUpperCase(),
                      style: TextStyle(fontSize: 10, color: visuals.textColor, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),

              ),
            ],
          ),
        );
      },
    );
  }
}