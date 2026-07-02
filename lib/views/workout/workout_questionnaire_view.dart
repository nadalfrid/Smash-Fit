// lib/views/workout/workout_questionnaire_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/workout/workout_questionnaire_controller.dart';
import 'plan_loading_view.dart'; 

class WorkoutQuestionnaireView extends StatefulWidget {
  const WorkoutQuestionnaireView({Key? key}) : super(key: key);

  @override
  State<WorkoutQuestionnaireView> createState() => _WorkoutQuestionnaireViewState();
}

class _WorkoutQuestionnaireViewState extends State<WorkoutQuestionnaireView> {
@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<WorkoutQuestionnaireController>();
      
      controller.reset();
      controller.initializeUserData();
      
      // 🟢 FIX: Prefetch master plans from cloud instantly on launch.
      // Bypasses network freezes when the user reaches the commitment step!
      if (controller.allPlans.isEmpty) {
        controller.fetchMasterPlansFromFirestore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutQuestionnaireController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA), 
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0, 
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
              onPressed: () => controller.previousPage(context),
            ),
            title: _buildProgressBar(controller),
            centerTitle: true,
          ),
          // 🟢 LOADING INTERCEPT: Gracefully displays while async fetch operations complete
          body: SafeArea(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF009688)),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: controller.pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: controller.updatePage,
                          children: [
                            _buildChoicePage(
                              title: "What do you want to achieve with your workout?",
                              options: ["Build Muscle", "Get Stronger", "Lose Fat"],
                              selectedValue: controller.selectedGoal,
                              onSelected: controller.setGoal,
                            ),
                            _buildChoicePage(
                              title: "What is your workout experience?",
                              options: ["Beginner (0-2 years)", "Intermediate (2-5 years)", "Advanced (5+ years)"],
                              selectedValue: controller.selectedExperience,
                              onSelected: controller.setExperience,
                            ),
                            _buildChoicePage(
                              title: "How many times do you want to work out per week?",
                              options: ["2 days / week", "3 days / week", "4 days / week", "5 days / week"],
                              selectedValue: controller.selectedFrequency,
                              onSelected: controller.setFrequency,
                            ),
                            _buildChoicePage(
                              title: "How long do you want to commit to this plan?",
                              options: ["4 weeks", "8 weeks", "12 weeks"],
                              selectedValue: controller.selectedCommitment,
                              onSelected: controller.setCommitment,
                            ),
                            _buildWeightSliderPage(controller),
                          ],
                        ),
                      ),
                      _buildNextButton(context, controller),
                    ],
                  ),
          ),
        );
      }
    );
  }

  Widget _buildProgressBar(WorkoutQuestionnaireController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(controller.totalPages, (index) {
        bool isCompletedOrCurrent = index <= controller.currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 6.0, 
          width: 32.0,
          decoration: BoxDecoration(
            color: isCompletedOrCurrent ? const Color(0xFF009688) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildChoicePage({
    required String title, 
    required List<String> options, 
    required String? selectedValue, 
    required Function(String) onSelected
  }) {
    return SingleChildScrollView( 
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title, 
            style: const TextStyle(color: Color(0xFF1A1C24), fontSize: 22, fontWeight: FontWeight.bold), 
            textAlign: TextAlign.center
          ),
          const SizedBox(height: 32),
          ...options.map((option) {
            bool isSelected = selectedValue == option;
            return GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF009688) : Colors.grey.shade200, 
                    width: isSelected ? 2.5 : 1.5
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded( 
                      child: Text(
                        option, 
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF009688) : const Color(0xFF2D3142), 
                          fontSize: 17, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Color(0xFF009688))
                    else
                      Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400)
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWeightSliderPage(WorkoutQuestionnaireController controller) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "What is your target weight?", 
              style: TextStyle(color: Color(0xFF1A1C24), fontSize: 22, fontWeight: FontWeight.bold), 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 6),
            const Text(
              "(Optional)", 
              style: TextStyle(color: Colors.grey, fontSize: 15), 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 32),
            
            // 🟢 Target Weight Slider ONLY
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Target Weight", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    // 🟢 FIX: Uses .round() to display a clean integer like "65 kg"
                    "${controller.targetWeight.round()} kg", 
                    style: const TextStyle(color: Color(0xFF1A1C24), fontSize: 26, fontWeight: FontWeight.bold)
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00897B),
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: const Color(0xFF00897B),
                    ),
                    child: Slider(
                      value: controller.targetWeight, 
                      min: 40, 
                      max: 150,
                      // 🟢 FIX: 110 divisions forces it to snap to exact 1kg increments
                      divisions: 110, 
                      label: "${controller.targetWeight.round()} kg", 
                      onChanged: controller.setTargetWeight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, WorkoutQuestionnaireController controller) {
    bool canProceed = controller.canProceed;
    bool isLastPage = controller.currentPage == controller.totalPages - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canProceed ? const Color(0xFF009688) : Colors.grey.shade300,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: canProceed ? () {
          if (isLastPage) {
            controller.generateRecommendations();
            
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const PlanLoadingView()),
            );
          } else {
            controller.nextPage();
          }
        } : null,
        child: Text(
          isLastPage ? "BUILD MY PLAN" : "NEXT",
          style: TextStyle(
            color: canProceed ? Colors.white : Colors.grey.shade500, 
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5
          ),
        ),
      ),
    );
  }
}