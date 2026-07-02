// lib/views/workout/widgets/workout_stats_header.dart
import 'package:flutter/material.dart';

class WorkoutStatsHeader extends StatelessWidget {
  final String durationFormatted;
  final int totalVolume;
  final int totalSets;

  const WorkoutStatsHeader({
    super.key,
    required this.durationFormatted,
    required this.totalVolume,
    required this.totalSets,
  });

  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat(Icons.timer_outlined, "Time", durationFormatted, Colors.teal),
          Container(width: 1, height: 30, color: Colors.grey.shade200), // Subtle divider
          _buildStat(Icons.fitness_center, "Volume", "$totalVolume kg", Colors.black87),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildStat(Icons.repeat, "Sets", "$totalSets", Colors.black87),
        ],
      ),
    );
  }
}