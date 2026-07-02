// lib/views/analysis/analysis_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../../controllers/analysis/exercise_analysis_controller.dart'; 
import '../../controllers/history/workout_history_controller.dart'; 
import '../../controllers/diet_controller.dart'; // 🟢 ADDED: Import your shared diet/food state tracker file path
import 'exercise_analysis_view.dart';
import 'diet_analysis_view.dart'; 
import 'workout_insight_view.dart'; 
import 'diet_insight_view.dart'; // 🟢 ADDED: Direct routing link to our incoming Step 4 layout view

class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Smash Fit Insights',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildSegmentedTabBar(),
          const SizedBox(height: 12),
          Expanded(child: _buildTabBarWorkspaceContent()),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabBar() {
    const Color smashFitPurple = Color(0xFF8B1FA9);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: smashFitPurple,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: smashFitPurple.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          tabs: const [
            Tab(text: 'Exercise'),
            Tab(text: 'Diet'),
            Tab(text: 'Workout'),
            Tab(text: 'Nutrition'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarWorkspaceContent() {
    final historyController = context.read<WorkoutHistoryController>();
    // 🟢 FETCH DIET BINDING: Captured your background database food tracker stream instance
    final sharedDietCtrl = context.read<DietController>(); 

    return TabBarView(
      controller: _tabController,
      children: [
        ChangeNotifierProvider<ExerciseAnalysisController>(
          create: (_) => ExerciseAnalysisController(),
          child: const ExerciseAnalysisView(),
        ),
        const DietAnalysisView(),
        WorkoutInsightView(sharedWorkoutController: historyController),
        // 🟢 ROUTING ROUTE REFACTOR: Replaced generic bento placeholder with active micro nutrition layout view sheet
        DietInsightView(sharedDietController: sharedDietCtrl),
      ],
    );
  }
}