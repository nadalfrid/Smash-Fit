import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/analysis/exercise_analysis_controller.dart';
import '../../controllers/diet_controller.dart'; 
import '../../utils/muscle_visuals.dart'; 
import 'widgets/calendar_filter_popover.dart';
import 'package:fl_chart/fl_chart.dart';

class ExerciseAnalysisView extends StatefulWidget {
  const ExerciseAnalysisView({super.key});

  @override
  State<ExerciseAnalysisView> createState() => _ExerciseAnalysisViewState();
}

class _ExerciseAnalysisViewState extends State<ExerciseAnalysisView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dietController = context.read<DietController>();
      context.read<ExerciseAnalysisController>().initAnalysisDashboard(dietController);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExerciseAnalysisController>();
    final dietController = context.watch<DietController>(); 
    final data = controller.analysisData;
    const Color smashFitTeal = Color(0xFF1E9E88);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIMELINE CONTROLS CARD
          GestureDetector(
            onTap: () {
              CalendarFilterPopover.show(
                context: context,
                initialStartDate: controller.startDate,
                initialEndDate: controller.endDate,
                onDatesSelected: (newStart, newEnd) {
                  controller.updateDateRange(newStart, newEnd, dietController);
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), spreadRadius: 0, blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: smashFitTeal, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${controller.startDate.day}/${controller.startDate.month}/${controller.startDate.year} - ${controller.endDate.day}/${controller.endDate.month}/${controller.endDate.year}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text("Tap to adjust analytics window filter", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // OVERVIEW GENERAL COUNTERS STATS ROW INDICATORS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStatItem("Total", "${controller.totalExercisesCount}", Colors.blueGrey),
                _buildSummaryStatItem("Gaining", "${controller.gainingCount}", const Color(0xFF16A34A)),
                _buildSummaryStatItem("Plateau", "${controller.plateauingCount}", const Color(0xFFEA580C)),
                _buildSummaryStatItem("Losing", "${controller.losingCount}", const Color(0xFFDC2626)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. SEARCH & STRENGTH SORT SELECTOR PANEL
          const Text("Select Movement", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (val) => controller.updateSearchQuery(val),
                    decoration: const InputDecoration(
                      hintText: "Search exercises...",
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<StrengthSortOrder>(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.swap_vert, color: smashFitTeal, size: 20),
                ),
                onSelected: (order) => controller.toggleSortOrder(order),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: StrengthSortOrder.highToLow,
                    child: Text("Strength: High to Low (Gaining)"),
                  ),
                  const PopupMenuItem(
                    value: StrengthSortOrder.lowToHigh,
                    child: Text("Strength: Low to High (Losing)"),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),

          // HORIZONTAL MOVEMENT CHIPS SELECTOR LIST
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.availableExercises.length,
              itemBuilder: (context, index) {
                final item = controller.availableExercises[index];
                final bool isSelected = item['id'] == controller.selectedExerciseId;
                final double variance = item['pct'] as double;
                
                Color statusColor = const Color(0xFFEA580C);
                if (item['status'] == 'gaining') statusColor = const Color(0xFF16A34A);
                if (item['status'] == 'losing') statusColor = const Color(0xFFDC2626);
                if (item['status'] == 'new') statusColor = const Color(0xFF4F46E5);

                return GestureDetector(
                  onTap: () => controller.selectExercise(item['id'], item['name'], dietController),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 185,
                    margin: const EdgeInsets.only(right: 10, bottom: 4, top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? smashFitTeal : const Color(0xFFE2E8F0), 
                        width: isSelected ? 2 : 1
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.01), spreadRadius: 0, blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13, 
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: const Color(0xFF1E293B)
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              item['status'] == 'gaining' ? Icons.trending_up : (item['status'] == 'losing' ? Icons.trending_down : (item['status'] == 'new' ? Icons.star_border : Icons.trending_flat)), 
                              color: statusColor, 
                              size: 14
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['status'] == 'new' ? "CALIBRATING" : "${item['status'].toString().toUpperCase()} @ ${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)}%",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),

          // LOADING STATE OR DETAIL INJECTION SECTION
          if (controller.isLoading) ...[
            const SizedBox(height: 60),
            const Center(child: CircularProgressIndicator(color: smashFitTeal)),
          ] else if (data != null) ...[
            const SizedBox(height: 12),
            // 3. EXERCISE TITLE & RECENT INSIGHT BADGE REGION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data.exerciseName, 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: data.statusLabel == "gaining" ? const Color(0xFFF0FDF4) : (data.statusLabel == "losing" ? const Color(0xFFFEF2F2) : (data.statusLabel == "new" ? const Color(0xFFEEF2FF) : const Color(0xFFFFF7ED))),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: data.statusLabel == "gaining" ? const Color(0xFFDCFCE7) : (data.statusLabel == "losing" ? const Color(0xFFFEE2E2) : (data.statusLabel == "new" ? const Color(0xFFE0E7FF) : const Color(0xFFFFEDD5)))
                    ),
                  ),
                  child: Text(
                    data.statusLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w900, 
                      color: data.statusLabel == "gaining" ? const Color(0xFF16A34A) : (data.statusLabel == "losing" ? const Color(0xFFDC2626) : (data.statusLabel == "new" ? const Color(0xFF4F46E5) : const Color(0xFFEA580C))), 
                      letterSpacing: 0.5
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 14),

            // TARGET MUSCLE ROW
            Builder(
              builder: (context) {
                final visuals = MuscleVisuals.getVisuals(data.targetMuscle);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: visuals.backgroundColor, borderRadius: BorderRadius.circular(12)),
                        child: _buildMockableImage(visuals.imagePath, width: 44, height: 44, placeholderIcon: Icons.accessibility_new),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("PRIMARY TARGET MUSCLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: visuals.backgroundColor, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              data.targetMuscle.toUpperCase(),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: visuals.textColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Insight Explainer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        data.statusLabel == "new" ? Icons.lock_clock : Icons.star_outline, 
                        color: data.statusLabel == "gaining" ? const Color(0xFF16A34A) : (data.statusLabel == "losing" ? const Color(0xFFDC2626) : (data.statusLabel == "new" ? const Color(0xFF4F46E5) : const Color(0xFFEA580C))), 
                        size: 18
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Performance Summary", 
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.statusLabel == "gaining"
                        ? "Great progress! Your strength trend shifted up by ${data.progressPercentage.abs().toStringAsFixed(1)}% over this timeline window. Your progressive overload strategy is working beautifully—keep pushing the intensity!"
                        : (data.statusLabel == "losing"
                            ? "Recovery or energy adjustment needed. Your strength metrics took a noticeable dip of ${data.progressPercentage.abs().toStringAsFixed(1)}% versus your historical baseline limits. Prioritize your sleep, hydration, and nutritional consistency."
                            : (data.statusLabel == "new"
                                ? "Calibration engine active. Log at least 3 historical workout sessions to map rolling progressive overload changes and generate performance indices."
                                : "You've hit a temporary strength plateau. Directional variance holds steady at ${data.progressPercentage.toStringAsFixed(1)}%. Consider altering your repetition ranges, execution tempo, or lifting volume splits to break through.")),
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE2E8F0), thickness: 1),
            const SizedBox(height: 12),

            // THE ADAPTIVE AI COACH STRATEGY CARD
            _buildAiCoachingCard(controller),
            const SizedBox(height: 24),

            // 4. STRENGTH PROGRESSION GRAPH REGION
            const Row(
              children: [
                Icon(Icons.show_chart, color: smashFitTeal, size: 20),
                 SizedBox(width: 8),
                Text("Strength Progression (1RM Estimation)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),

            if (data.statusLabel == "new") ...[
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insights, color: Colors.indigo[300], size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      "Progression Chart Locked", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15)
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        "Insufficient tracking volume history. Log more sessions to calibrate baseline progression indices.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.only(right: 24, left: 8, top: 20, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(color:Color(0xFFF1F5F9), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < data.workoutDates.length) {
                              DateTime date = data.workoutDates[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "${date.day}/${date.month}",
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              "${value.toStringAsFixed(0)}kg",
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (data.estimatedOneRepMaxHistory.length - 1).toDouble(),
                    minY: (data.estimatedOneRepMaxHistory.reduce((a, b) => a < b ? a : b) - 5).clamp(0, double.infinity),
                    maxY: data.estimatedOneRepMaxHistory.reduce((a, b) => a > b ? a : b) + 5,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          data.estimatedOneRepMaxHistory.length,
                          (index) => FlSpot(index.toDouble(), data.estimatedOneRepMaxHistory[index]),
                        ),
                        isCurved: true,
                        color: smashFitTeal,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: smashFitTeal,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: smashFitTeal.withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            const Divider(color: Color(0xFFE2E8F0), thickness: 1),
            const SizedBox(height: 12),

            // 5. WINDOW PERFORMANCE STATS REGION
            const Row(
              children: [
                Icon(Icons.bar_chart, color: smashFitTeal, size: 20),
                 SizedBox(width: 8),
                Text("Window Performance Statistics", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final items = [
                  _buildStatTile("Best Weight", "${data.bestWeightLIFTED} kg", Icons.fitness_center),
                  _buildStatTile("Total Sets Logged", "${data.totalSetsLogged} Sets", Icons.layers),
                  _buildStatTile("Workout Sessions", "${data.totalSessionsCount} Logs", Icons.assignment_turned_in),
                  _buildStatTile("Avg Reps Depth", "${data.averageRepsPerSet} Reps", Icons.repeat),
                ];

                return items[index];
              },
            )
          ]
        ],
      ),
    );
  }

  Widget _buildAiCoachingCard(ExerciseAnalysisController controller) {
    const Color smashFitTeal = Color(0xFF1E9E88);
    final textContent = controller.analysisData?.aiCoachingTip;
    final dietController = context.read<DietController>(); 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[900]!, const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: smashFitTeal.withOpacity(0.15), spreadRadius: 0, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 18),
                SizedBox(width: 8),
                Expanded(
                child: Text(
                  "SMASH FIT EXERCISE STRATEGY",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF99F6E4), 
                    letterSpacing: 0.8
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (controller.isAiLoading) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    "Coach Gemini is evaluating your lifting micro-trends...",
                    softWrap: true,
                    style: TextStyle(
                      color: Colors.blueGrey[300],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (textContent != null) ...[
            Text(
              textContent,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: smashFitTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 2,
                ),
                icon: const Icon(Icons.bolt, size: 16, color: Color(0xFF38BDF8)),
                label: const Text("GENERATE COACH INSIGHT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                onPressed: () {
                  final String name = dietController.userProfile?.name ?? "Fitness Enthusiast";
                  controller.triggerManualAiUpdate(name);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildMockableImage(String assetPath, {required double width, required double height, required IconData placeholderIcon}) {
    if (assetPath.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Icon(placeholderIcon, color: const Color(0xFF94A3B8), size: 20),
      );
    }
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
          child: Icon(placeholderIcon, color: const Color(0xFF94A3B8), size: 20),
        );
      },
    );
  }

  Widget _buildStatTile(String label, String metric, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), spreadRadius: 0, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF64748B), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      metric, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
}