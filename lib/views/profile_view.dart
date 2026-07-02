import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../services/health_service.dart';
import 'edit_profile_view.dart';
import 'login_view.dart'; 
import '../controllers/diet_controller.dart';
import '../controllers/history/workout_history_controller.dart';
import 'package:provider/provider.dart';
import '../controllers/workout/workout_questionnaire_controller.dart';
import 'report_prompt_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.teal),
            SizedBox(width: 10),
            Text("Logout"),
          ],
        ),
        content: const Text("Are you sure you want to sign out of your Smash Fit account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.pop(ctx); 
              _handleLogout();    
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _handleLogout() async {
    try {
      // 1. Terminate background stream references synchronously for global controllers
      Provider.of<DietController>(context, listen: false).clearSession();
      Provider.of<WorkoutHistoryController>(context, listen: false).clearSession();
      Provider.of<WorkoutQuestionnaireController>(context, listen: false).clearSession();
      
      // 2. Clear the layout navigation stack instantly!
      // Doing this FIRST removes the StreamBuilder from the screen,
      // so it stops listening BEFORE we kill the Firebase token.
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const LoginView()), 
          (route) => false, 
        );
      }

      // 3. Clear out the Firebase session token AFTER the UI has unmounted
      // We add a tiny microsecond delay to ensure the widget tree is fully destroyed
      await Future.delayed(const Duration(milliseconds: 200));
      await FirebaseService().signOut();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

@override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel>(
      stream: FirebaseService().getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        }
        
        if (snapshot.hasError) {
          return const SizedBox.shrink(); 
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("No User Data Found"));
        }

        final user = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 20),

              // --- Modernized Body Stats Container ---
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column( 
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF2A9D8F)),
                          const SizedBox(width: 8),
                          const Text(
                            "Body Stats",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF233036),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5), 
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: _buildStatItem(user.weight.toString(), "Weight (kg)")),
                          _buildVerticalDivider(),
                          Expanded(child: _buildStatItem(user.height.toInt().toString(), "Height (cm)")),
                          _buildVerticalDivider(),
                          Expanded(child: _buildAgeStat(user.age)),
                          _buildVerticalDivider(),
                          Expanded(child: _buildStatItem(user.bmi.toString(), "BMI", isTag: true, userModel: user)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _buildHealthDetailsCard(user),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileView(user: user),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
              ),
              
              const SizedBox(height: 12), // Added spacing

              // --- NEW CODE: Export Progress Button ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Matched to Edit Profile button
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text(
                    "Export Progress Report",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportPromptView(user: user), // Pass the user model here!
                      ),
                    );
                  },
                ),
              ),
              // --- END NEW CODE ---

              const SizedBox(height: 20), // Added spacing

              TextButton.icon(
                onPressed: _showLogoutConfirmation,
                icon: const Icon(Icons.logout, color: Colors.grey),
                label: const Text("Logout", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthDetailsCard(UserModel user) {
    String proteinRange = HealthService.calculateProteinRange(
      age: user.age,
      weight: user.weight,
      gender: user.gender, 
    );
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                "Personalized Health Insights",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInsightItem("${user.tdee.toInt()}", "kcal", "Daily Calorie", Icons.local_fire_department),
              _buildVerticalDivider(),
              _buildInsightItem(proteinRange, "", "Protein Target", Icons.egg_alt), 
              _buildVerticalDivider(),
              _buildInsightItem(user.activityLevel.displayName, "", "Activity", Icons.directions_run),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, {bool isTag = false, UserModel? userModel}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isTag && userModel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: _getBmiColor(userModel.bmi).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20), 
            ),
            child: Text(
              userModel.bmiCategory,
              style: TextStyle(
                color: _getBmiColor(userModel.bmi),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          )
        else
          const SizedBox(height: 25), 
        
        Text(
          val, 
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: Color(0xFF233036), 
          ),
        ),
        
        Text(
          label, 
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B8B8B), 
          ),
        ),
      ],
    );
  }

  Widget _buildAgeStat(int currentAge) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 25), 
        Text(
          currentAge.toString(),
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: Color(0xFF233036), 
          ),
        ),
        Text(
          "Age",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B8B8B), 
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 45, 
            backgroundColor: Color(0xFF2A9D8F), 
            child: Icon(Icons.person, color: Colors.white, size: 45),
          ),
        ),
        const SizedBox(height: 20),
        
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: Color(0xFF233036), 
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8B8B8B), 
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildVerticalDivider() => Container(
    height: 40, 
    width: 1, 
    color: const Color(0xFFEFEFEF), 
  );

  Widget _buildInsightItem(String value, String unit, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade300),
          const SizedBox(height: 8),
          FittedBox( 
            fit: BoxFit.scaleDown,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                children: [
                  TextSpan(text: value),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: " $unit",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}