// lib/views/exercise/exercise_detail_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/exercise_service.dart';
import '../../controllers/exercise/exercise_detail_controller.dart';

class ExerciseDetailView extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailView({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<ExerciseDetailView> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseDetailController>().loadExercise(widget.exerciseId);
    });
  }

  // --- HELPER: Dynamic Difficulty Colors ---
  Color _getDifficultyColor(String? difficulty) {
    if (difficulty == null) return Colors.blueGrey;
    final d = difficulty.toLowerCase();
    if (d == 'beginner') return Colors.green.shade600;
    if (d == 'intermediate') return Colors.orange.shade600;
    if (d == 'advanced') return Colors.red.shade600;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final detailCtrl = context.watch<ExerciseDetailController>();

    if (detailCtrl.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    if (detailCtrl.exercise == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text("Exercise details not found.")),
      );
    }

    final exercise = detailCtrl.exercise!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(
            color: Colors.black87, 
            fontWeight: FontWeight.w800, 
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // ==========================================
            // 1. HERO SECTION: GIF VIEWER
            // ==========================================
            if (exercise.gifUrls != null && exercise.gifUrls!.isNotEmpty)
              Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 2)),
                ),
                child: PageView.builder(
                  itemCount: exercise.gifUrls!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          exercise.gifUrls![index],
                          fit: BoxFit.contain,
                          headers: {
                            'X-WorkoutX-Key': ExerciseService.apiKey, 
                          },
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // ==========================================
                  // 2. QUICK STATS TAGS
                  // ==========================================
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Difficulty (Dynamic Color)
                      if (exercise.difficulty != null)
                        _buildChip(
                          exercise.difficulty!, 
                          _getDifficultyColor(exercise.difficulty), 
                          icon: Icons.speed
                        ),
                      
                      // Equipment
                      _buildChip(exercise.equipment, Colors.blueGrey, icon: Icons.fitness_center),
                      
                      // Mechanic (Compound / Isolation)
                      if (exercise.mechanic != null)
                        _buildChip(exercise.mechanic!, Colors.indigo, icon: Icons.settings_suggest),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ==========================================
                  // 3. MUSCLES WORKED SECTION
                  // ==========================================
                  const Text("Muscles Worked", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5, color: Colors.black87)),
                  const SizedBox(height: 16),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary Target
                        Row(
                          children: [
                            Icon(Icons.adjust, size: 16, color: Colors.teal.shade700),
                            const SizedBox(width: 8),
                            const Text("Primary: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text(
                              exercise.targetMuscle.toUpperCase(),
                              style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        
                        // Secondary Muscles
                        if (exercise.secondaryMuscles != null && exercise.secondaryMuscles!.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.control_point_duplicate, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              const Text("Secondary: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              Expanded(
                                child: Text(
                                  exercise.secondaryMuscles!.map((m) => m.toUpperCase()).join(", "),
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==========================================
                  // 4. OVERVIEW SECTION
                  // ==========================================
                  if (exercise.overview != null && exercise.overview!.isNotEmpty) ...[
                    const Text("Overview", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Text(
                      exercise.overview!,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.6),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ==========================================
                  // 5. INSTRUCTIONS SECTION
                  // ==========================================
                  const Text("Instructions", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5, color: Colors.black87)),
                  const SizedBox(height: 16),

                  if (exercise.instructions != null && exercise.instructions!.isNotEmpty)
                    ...exercise.instructions!.asMap().entries.map((entry) {
                      int idx = entry.key + 1;
                      String text = entry.value;
                      return _buildInstructionStep(idx, text);
                    })
                  else
                    const Text("No instructions available.", style: TextStyle(color: Colors.grey)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER: MODERN CHIP ---
  Widget _buildChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color, 
              fontSize: 12, 
              fontWeight: FontWeight.w800, 
              letterSpacing: 0.5
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER: MODERN INSTRUCTION STEP ---
  Widget _buildInstructionStep(int stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: TextStyle(
                  color: Colors.teal.shade800, 
                  fontSize: 13, 
                  fontWeight: FontWeight.w900
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}