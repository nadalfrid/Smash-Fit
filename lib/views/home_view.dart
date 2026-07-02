import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'diet_view.dart';
import 'workout/workout_view.dart';
import '../../controllers/workout/workout_questionnaire_controller.dart';
import '../../controllers/diet_controller.dart'; 
import '../controllers/weight_controller.dart';
import 'weight_tracking_view.dart';
import 'edit_profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutQuestionnaireController>().loadUserActivePlanFromCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🌍 Consumes live statistics bound exclusively to the current calendar day
    final dietProvider = context.watch<DietController>();

    final double dailyGoal = dietProvider.targetCalories.toDouble();
    final double consumed = dietProvider.currentCalories.toDouble();
    final double p = dietProvider.currentProtein.toDouble();
    final double c = dietProvider.currentCarbs.toDouble();
    final double f = dietProvider.currentFat.toDouble();
    final double maxP = dietProvider.maxProtein.toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // --- 1. HEADER (REFACTORED FOR PROPER ARCHITECTURE LIFE-CYCLES) ---
            Consumer<DietController>(
              builder: (context, dietController, child) {
                final userProfile = dietController.userProfile;
                final String userName = userProfile?.name ?? "User";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, $userName",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF233036)),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: const TextStyle(color: Color(0xFF8B8B8B)),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),

            // --- 2. HEALTH DASHBOARD (TODAY ONLY) ---
            Column(
              children: [
                _buildModernRingCard(consumed, dailyGoal, p, c, f, maxP),
                const SizedBox(height: 30),
                _buildQuickActions(context),
              ],
            ),

            const SizedBox(height: 30),
            _buildAICoachCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModernRingCard(double consumed, double target, double p, double c, double f, double pTarget) {
    double progress = target > 0 ? (consumed / target) : 0.0;
    int remaining = (target - consumed).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  strokeWidth: 14,
                  backgroundColor: const Color(0xFFEFEFEF),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2A9D8F)),
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${remaining < 0 ? 0 : remaining}",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF233036))),
                    const Text("kcal left", style: TextStyle(color: Color(0xFF8B8B8B), fontSize: 14)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroStat("Protein", "${p.toInt()}g", p / pTarget, Colors.orange),
              _buildMacroStat("Carbs", "${c.toInt()}g", c / 200, Colors.blue),
              _buildMacroStat("Fat", "${f.toInt()}g", f / 65, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStat(String label, String value, double pct, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8B8B8B))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF233036))),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: pct.clamp(0, 1),
            backgroundColor: const Color(0xFFEFEFEF),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionCircle(context, "Workout", Icons.fitness_center, const Color(0xFF2A9D8F), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutView()));
        }),
        _buildActionCircle(context, "Meal", Icons.restaurant, Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DietView()));
        }),
        _buildActionCircle(context, "Weight", Icons.monitor_weight_outlined, const Color(0xFF673AB7), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightTrackingView()));
        }),
      ],
    );
  }

  Widget _buildActionCircle(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(25), // 🌟 Upgraded non-deprecated alternative to withOpacity
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF233036))),
        ],
      ),
    );
  }

  Widget _buildAICoachCard(BuildContext context) {
    // 🟢 Listen to the WeightController's math engine
    final isMilestoneAchieved = context.watch<WeightController>().isMilestoneAchieved;

    // If there is no milestone, show absolutely nothing.
    if (!isMilestoneAchieved) {
      return const SizedBox.shrink();
    }

    // 🏆 THE MILESTONE NOTIFICATION
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
            side: const BorderSide(color: Color(0xFF673AB7), width: 1.5)
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars, color: Color(0xFF673AB7), size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Milestone Achieved!", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF673AB7))
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Fantastic progress! You've achieved a 5% shift toward your goal. Let's update your profile metrics to keep your macros optimized for your new body mass.", 
                  style: TextStyle(color: Colors.black87)
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                    // 🟢 1. Grab the active user profile from your existing DietController
                    final activeUser = context.read<DietController>().userProfile;

                    if (activeUser != null) {
                      // 🟢 2. Safely pass the user object into the EditProfileView
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => EditProfileView(user: activeUser))
                      );
                    } else {
                      // Fallback just in case the profile hasn't finished streaming yet
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile data loading, please try again in a moment.")),
                      );
                    }
                  },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Update Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 20), // Spacing below the card when it is visible
      ],
    );
  }

}