import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/weight_controller.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightTrackingView extends StatefulWidget {
  const WeightTrackingView({Key? key}) : super(key: key);

  @override
  State<WeightTrackingView> createState() => _WeightTrackingViewState();
}

class _WeightTrackingViewState extends State<WeightTrackingView> {
  double _selectedWeight = 0.0;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely initialize the stepper with their actual current weight from the controller
    if (!_isInitialized) {
      final currentWeight = context.read<WeightController>().currentWeight;
      _selectedWeight = currentWeight > 0 ? currentWeight : 70.0; // Fallback to 70kg if new
      _isInitialized = true;
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    
    try {
      // 🟢 Calls the isolated save method in our new WeightController
      await context.read<WeightController>().saveNewWeight(_selectedWeight);
      if (mounted) {
        Navigator.pop(context); // Return to home screen on success
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update weight. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 Read the target weight and the new historical spots from the controller
    final weightProvider = context.watch<WeightController>();
    final targetWeight = weightProvider.targetWeight;
    final historySpots = weightProvider.weightHistorySpots;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF233036)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Weight Progress",
          style: TextStyle(color: Color(0xFF233036), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // --- THE PLUS/MINUS STEPPER ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  const Text("Log Today's Weight", style: TextStyle(fontSize: 14, color: Color(0xFF8B8B8B), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () { if (_selectedWeight > 30) setState(() => _selectedWeight -= 1); },
                        icon: const Icon(Icons.remove_circle_outline, size: 42, color: Color(0xFF2A9D8F)),
                      ),
                      Container(
                        width: 130,
                        alignment: Alignment.center,
                        child: Text(
                          "${_selectedWeight.round()} kg",
                          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFF233036)),
                        ),
                      ),
                      IconButton(
                        onPressed: () { if (_selectedWeight < 250) setState(() => _selectedWeight += 1); },
                        icon: const Icon(Icons.add_circle_outline, size: 42, color: Color(0xFF2A9D8F)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // --- FL CHART: 7-DAY TREND ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Trend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF233036)),
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 24, right: 24, left: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                // 🟢 Pass the real data into the chart builder
                child: historySpots.isEmpty 
                    ? const Center(
                        child: Text(
                          "Save a weight to start your chart!", 
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
                        )
                      )
                    : _buildWeightChart(historySpots, targetWeight),
              ),
            ),

            const SizedBox(height: 24),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text("SAVE UPDATE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 🟢 The Dynamic FL Chart Implementation
  Widget _buildWeightChart(List<FlSpot> realData, double targetWeight) {
    // 1. DYNAMIC SCALING: Find the highest and lowest weight in their history
    double minWeight = realData.first.y;
    double maxWeight = realData.first.y;

    for (var spot in realData) {
      if (spot.y < minWeight) minWeight = spot.y;
      if (spot.y > maxWeight) maxWeight = spot.y;
    }

    // Factor in the target weight so the dashed line always fits on the screen
    if (targetWeight > 0) {
      if (targetWeight < minWeight) minWeight = targetWeight;
      if (targetWeight > maxWeight) maxWeight = targetWeight;
    }

    // Add 2kg padding to top and bottom so the line doesn't hit the exact edges of the box
    double chartMinY = minWeight - 2;
    double chartMaxY = maxWeight + 2;

    // The X-axis max is always the length of the data minus 1
    double chartMaxX = (realData.length - 1).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 2,
              getTitlesWidget: (value, meta) {
                // Ensure we don't show decimals on the Y axis for cleaner look
                return Text("${value.toInt()}", style: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 12));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: chartMinY, 
        maxY: chartMaxY,
        minX: 0,
        maxX: chartMaxX, // Ensure the dashed line spans exactly across the real data
        lineBarsData: [
          // The Real Data Trendline
          LineChartBarData(
            spots: realData,
            isCurved: true,
            color: const Color(0xFF2A9D8F),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2A9D8F).withAlpha(30), 
            ),
          ),
          // Target Weight Dashed Line
          if (targetWeight > 0)
            LineChartBarData(
              spots: [
                FlSpot(0, targetWeight),
                FlSpot(chartMaxX, targetWeight), // Spans dynamically across available data
              ],
              isCurved: false,
              color: Colors.redAccent.withAlpha(150),
              barWidth: 2,
              isStrokeCapRound: true,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }
}