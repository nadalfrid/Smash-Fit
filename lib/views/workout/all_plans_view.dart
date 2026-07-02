// lib/views/workout/all_plans_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/workout/workout_questionnaire_controller.dart';
import '../../models/workout_plan_model.dart';
import 'package:smash_fit/views/workout/workout_plan_preview_view.dart';

class AllPlansView extends StatefulWidget {
  const AllPlansView({Key? key}) : super(key: key);

  @override
  State<AllPlansView> createState() => _AllPlansViewState();
}

class _AllPlansViewState extends State<AllPlansView> {
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Beginner", "Intermediate", "Advanced"];

  @override
  void initState() {
    super.initState();
    // 🟢 FETCH TRIGGER: Ensures templates are loaded from the cloud if the catalog is opened directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<WorkoutQuestionnaireController>();
      if (controller.allPlans.isEmpty) {
        controller.fetchMasterPlansFromFirestore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "All Workout Plans",
          style: TextStyle(color: Color(0xFF1A1C24), fontSize: 20, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C24)),
          onPressed: () => Navigator.pop(context),
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.0)),
      ),
      body: Consumer<WorkoutQuestionnaireController>(
        builder: (context, controller, child) {
          // 🟢 LOADING GATE: Shows a loading wheel during active cloud fetching
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF009688)),
              ),
            );
          }

          final filteredPlans = controller.allPlans.where((plan) {
            if (_selectedFilter == "All") return true;
            if (_selectedFilter == "Beginner") return plan.id.startsWith('beg');
            if (_selectedFilter == "Intermediate") {
              return plan.id.startsWith('int') || plan.id == 'test_plan';
            }
            if (_selectedFilter == "Advanced") return plan.id.startsWith('adv');
            return false;
          }).toList();

          return Column(
            children: [
              // --- HORIZONTAL FILTER ROW ---
              Container(
                height: 70,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filterName = _filters[index];
                    final bool isActive = _selectedFilter == filterName;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filterName),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.purple.shade600 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isActive ? Colors.purple.shade400 : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              filterName,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- FILTERED PLAN LIST ---
              Expanded(
                child: filteredPlans.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredPlans.length,
                        itemBuilder: (context, index) {
                          return _buildCatalogCard(context, controller, filteredPlans[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCatalogCard(BuildContext context, WorkoutQuestionnaireController controller, WorkoutPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    plan.difficulty.split(' (').first.toUpperCase(),
                    style: TextStyle(color: Colors.purple.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  plan.durationText.split(' • ').first,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.title,
              style: const TextStyle(color: Color(0xFF1A1C24), fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              plan.shortDescription,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple.shade600,
                elevation: 0,
                side: BorderSide(color: Colors.purple.shade100),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: controller,
                      child: WorkoutPlanPreviewView(plan: plan),
                    ),
                  ),
                );
              },
              child: const Text("PREVIEW PLAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No plans found for this level.",
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}