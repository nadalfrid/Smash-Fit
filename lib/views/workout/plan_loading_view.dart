// lib/views/workout/plan_loading_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/workout/workout_questionnaire_controller.dart';
import '../../models/workout_plan_model.dart';
import 'workout_roadmap_view.dart';
import 'workout_plan_preview_view.dart';

class PlanLoadingView extends StatefulWidget {
  const PlanLoadingView({Key? key}) : super(key: key);

  @override
  State<PlanLoadingView> createState() => _PlanLoadingViewState();
}

class _PlanLoadingViewState extends State<PlanLoadingView> {
  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // FIXED: Capture the active calculated data controller before the view shifts
      final activeController = Provider.of<WorkoutQuestionnaireController>(context, listen: false);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PlanRecommendationsView(existingController: activeController),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Color(0xFF009688),
                strokeWidth: 4.5,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Building your plan...",
              style: TextStyle(color: Color(0xFF1A1C24), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Tailoring routines to your personalized goals",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanRecommendationsView extends StatelessWidget {
  // FIXED: Receive the data-filled controller instance explicitly via parameters
  final WorkoutQuestionnaireController existingController;

  const PlanRecommendationsView({Key? key, required this.existingController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIXED: Use ChangeNotifierProvider.value to pass the active controller down to the view
    return ChangeNotifierProvider.value(
      value: existingController,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            "Recommended Plans",
            style: TextStyle(color: Color(0xFF1A1C24), fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C24)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<WorkoutQuestionnaireController>(
          builder: (context, controller, child) {
            final plans = controller.recommendedPlans;

            if (plans.isEmpty) {
              return const Center(
                child: Text("No plans match your criteria right now.", style: TextStyle(color: Color(0xFF2D3142))),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      return _buildPlanCard(context, controller, plans[index]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // Changed background color to show it is active and clickable
                      backgroundColor: const Color(0xFF1A1C24), 
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    // Linked the button press to call the controller navigation method
                    onPressed: () => controller.navigateToAllPlansCatalog(context), 
                    child: const Text(
                      "VIEW ALL PLANS", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

 Widget _buildPlanCard(BuildContext context, WorkoutQuestionnaireController controller, WorkoutPlan plan) {
    final int frequencyCount = plan.weeklyRoutine?.length ?? 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 16, offset: const Offset(0, 6))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple.shade400, size: 14),
                const SizedBox(width: 6),
                Text(
                  "RECOMMENDATION",
                  style: TextStyle(color: Colors.purple.shade400, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            Text(
              plan.title,
              style: const TextStyle(color: Color(0xFF1A1C24), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),

            Text(
              "$frequencyCount Sessions per Week • 60-90 Minutes Daily",
              style: TextStyle(color: Colors.purple.shade600, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.commonExercises.map((muscle) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    muscle,
                    style: TextStyle(color: Colors.purple.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text(
              plan.fullDescription,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),

            // FIXED: Activated the Learn More button to route to the preview deck
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade600, // Updated color signature to match active status
                side: BorderSide(color: Colors.purple.shade200),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: controller, // Share the active survey memory safely
                      child: WorkoutPlanPreviewView(plan: plan),
                    ),
                  ),
                );
              }, 
              child: const Text("LEARN MORE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final frequency = controller.selectedFrequency ?? "3 days / week";
                final commitment = controller.selectedCommitment ?? "4 weeks";

                int daysPerWeek = int.parse(frequency.substring(0, 1));
                int weeksCount = int.parse(commitment.substring(0, 1));

                // 🟢 1. Trigger the persistent cloud save operation first
                // Shows a basic loader using the loading flag we added
                await controller.saveUserSelectedPlanToCloud(plan);

                // 🟢 2. Route safely over to the Roadmap view with your data intact
                if (context.mounted) {
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
              child: controller.isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("SELECT PLAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}