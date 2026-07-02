import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/report_controller.dart'; // Adjust path if necessary
import '../models/user_model.dart';

class ReportPromptView extends StatelessWidget {
  final UserModel user; // Add this
  const ReportPromptView({Key? key, required this.user}) : super(key: key); // Add required

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Matches a clean, off-white theme
      appBar: AppBar(
        title: const Text(
          "Export Progress Report",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Consumer<ReportController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: Timeframe Selection ---
                const Text(
                  "Select Timeframe",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  children: [
                    _buildTimeframeChip(context, controller, "1 Month", ReportTimeframe.oneMonth),
                    _buildTimeframeChip(context, controller, "3 Months", ReportTimeframe.threeMonths),
                    _buildTimeframeChip(context, controller, "6 Months", ReportTimeframe.sixMonths),
                    _buildTimeframeChip(context, controller, "All Time", ReportTimeframe.allTime),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),

                // --- SECTION 2: Body Stats & Progress ---
                const Text(
                  "Body Composition",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeColor: Colors.teal,
                        title: const Text("Weight Change Trend"),
                        value: controller.includeWeightTrend,
                        onChanged: (val) => controller.toggleMetric('weightTrend'),
                      ),
                      SwitchListTile(
                        activeColor: Colors.teal,
                        title: const Text("BMI Status Track"),
                        value: controller.includeBmiTrack,
                        onChanged: (val) => controller.toggleMetric('bmiTrack'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- SECTION 3: Diet & Nutrition ---
                const Text(
                  "Nutrition Overview",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeColor: Colors.teal,
                        title: const Text("Average Daily Caloric Intake"),
                        value: controller.includeCalories,
                        onChanged: (val) => controller.toggleMetric('calories'),
                      ),
                      SwitchListTile(
                        activeColor: Colors.teal,
                        title: const Text("Macronutrient Target Consistency"),
                        value: controller.includeMacros,
                        onChanged: (val) => controller.toggleMetric('macros'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- SECTION 4: Workout Performance ---
                const Text(
                  "Training Metrics",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeColor: Colors.teal,
                        title: const Text("Total Training Volume"),
                        value: controller.includeTotalVolume,
                        onChanged: (val) => controller.toggleMetric('totalVolume'),
                      ),
                      SwitchListTile(
                        activeColor: Colors.teal,
                        title: const Text("Total Sets Completed"),
                        value: controller.includeTotalSets,
                        onChanged: (val) => controller.toggleMetric('totalSets'),
                      ),
                      SwitchListTile(
                        activeColor: Colors.teal,
                        title: const Text("Most Trained Muscle Group"),
                        value: controller.includeMuscleGroup,
                        onChanged: (val) => controller.toggleMetric('muscleGroup'),
                      ),
                    ],
                  ),
                ),
                
                // Bottom spacing before button
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      
      // --- BOTTOM ACTION BUTTON ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<ReportController>(
            builder: (context, controller, child) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: controller.isGenerating 
                    ? null 
                    : () => controller.generateReport(context, user),
                  child: controller.isGenerating
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          "Generate PDF",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper widget to keep the chip code clean
  Widget _buildTimeframeChip(BuildContext context, ReportController controller, String label, ReportTimeframe value) {
    // 1. This boolean checks if the chip matches the state in your controller
    final isSelected = controller.selectedTimeframe == value;
    
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      ),
      selected: isSelected,
      selectedColor: Colors.teal, // The color when active
      backgroundColor: Colors.grey[200],
      onSelected: (bool selected) {
        // 2. This is the crucial part: if selected, update the state
        if (selected) {
          controller.setTimeframe(value); 
        }
      },
    );
  }
}