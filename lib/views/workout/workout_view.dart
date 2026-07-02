// lib/views/workout/workout_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smash_fit/views/workout/workout_roadmap_view.dart'; 

import '../../models/workout_plan_model.dart';
import '../../controllers/history/workout_history_controller.dart'; 
import '../../controllers/workout/workout_questionnaire_controller.dart';
import 'active_workout_view.dart';
import 'widgets/workout_history_card.dart'; 
import 'workout_questionnaire_view.dart';
import 'widgets/workout_calendar_popup.dart';

class WorkoutView extends StatefulWidget {
  const WorkoutView({super.key});

  @override
  State<WorkoutView> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends State<WorkoutView> {
  late DateTime _weekPivotDate;

  @override
  void initState() {
    super.initState();
    _weekPivotDate = DateTime.now();
  }

  List<DateTime> _generateCurrentWeekDays() {
    final int currentWeekdayOffset = _weekPivotDate.weekday - 1;
    final DateTime mondayStart = _weekPivotDate.subtract(Duration(days: currentWeekdayOffset));
    return List.generate(7, (index) => mondayStart.add(Duration(days: index)));
  }

  void _shiftWeek(int weeksOffset) {
    setState(() {
      _weekPivotDate = _weekPivotDate.add(Duration(days: weeksOffset * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyController = context.watch<WorkoutHistoryController>();
    final now = DateTime.now();
    final DateTime todayMidnightCeiling = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Workout", 
          style: TextStyle(color: Color(0xFF233036), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: Consumer<WorkoutQuestionnaireController>(
        builder: (context, planController, child) {
          final activePlans = planController.recommendedPlans;
          final hasActivePlan = activePlans.isNotEmpty;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. MANUAL QUICK START
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const ActiveWorkoutView()),
                    );
                  },
                  child: _buildModernGradientCard(),
                ),
                const SizedBox(height: 16),

                // 2. DYNAMIC PROGRAM AI CARD HUB
                hasActivePlan 
                  ? _buildActivePlanCard(context, planController, activePlans.first)
                  : GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WorkoutQuestionnaireView()),
                        );
                      },
                      child: _buildModernAICard(),
                    ),
                const SizedBox(height: 36),

                // 3. 📅 INLINE WEEK-STRIP & CONTROL CONTEXT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "History", 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF233036), letterSpacing: -0.5)
                    ),
                    _buildUnifiedMonthBadgeControls(todayMidnightCeiling),
                  ],
                ),
                const SizedBox(height: 14),

                // THE HORIZONTAL SLIDER COMPONENT CONTAINER
                _buildHorizontalWeekStripSlider(historyController, todayMidnightCeiling),
                const SizedBox(height: 12),

                // Selected Target Day Subtitle Anchor Label display
                Text(
                  DateFormat('EEEE, d MMM yyyy').format(historyController.selectedDate),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8B8B8B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // 4. THE LIVE DYNAMIC VIEWPORT LAYER RECAP ENTRIES
                historyController.filteredLogs.isEmpty
                    ? _buildEmptyHistoryFallback()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: historyController.filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = historyController.filteredLogs[index];
                          return WorkoutHistoryCard(log: log); 
                        },
                      ),
                
                const SizedBox(height: 40), 
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnifiedMonthBadgeControls(DateTime todayCeiling) {
    final String monthHeaderLabel = DateFormat('MMM yyyy').format(_weekPivotDate);
    
    final DateTime nextWeekMonday = _weekPivotDate.add(const Duration(days: 7));
    final bool isNextWeekInFuture = nextWeekMonday.isAfter(todayCeiling);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF233036)),
            onPressed: () => _shiftWeek(-1),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          
          // 🟢 FIXED: INKWELL TRIGGER FOR CALENDAR POPUP
          InkWell(
            onTap: () {
              context.read<WorkoutHistoryController>().initCalendarPopup();
              showDialog(
                context: context,
                builder: (context) => const WorkoutCalendarPopup(),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                monthHeaderLabel, 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF233036))
              ),
            ),
          ),

          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded, 
              size: 18, 
              color: isNextWeekInFuture ? const Color(0xFFE2E8F0) : const Color(0xFF233036)
            ),
            onPressed: isNextWeekInFuture ? null : () => _shiftWeek(1),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalWeekStripSlider(WorkoutHistoryController controller, DateTime todayCeiling) {
    final List<DateTime> weekDaysList = _generateCurrentWeekDays();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDaysList.map((cellDate) {
          final String dotKey = "${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";
          final bool hasTrackedWorkout = controller.datesWithWorkouts.contains(dotKey);
          
          final bool isSelected = cellDate.year == controller.selectedDate.year &&
                                  cellDate.month == controller.selectedDate.month &&
                                  cellDate.day == controller.selectedDate.day;

          final bool isFutureDay = cellDate.isAfter(todayCeiling);

          return GestureDetector(
            onTap: isFutureDay ? null : () => controller.updateSelectedDate(cellDate),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2A9D8F) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Opacity(
                opacity: isFutureDay ? 0.30 : 1.0, 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('E').format(cellDate), 
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold, 
                        color: isSelected ? Colors.white : const Color(0xFF8B8B8B)
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${cellDate.day}",
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w800, 
                        color: isSelected ? Colors.white : const Color(0xFF233036)
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 4,
                      width: 4,
                      decoration: BoxDecoration(
                        color: hasTrackedWorkout
                            ? (isSelected ? Colors.white : const Color(0xFF2A9D8F))
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModernGradientCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F766E).withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Transform.rotate(
              angle: -0.2,
              child: FaIcon(FontAwesomeIcons.dumbbell, size: 140, color: Colors.white.withOpacity(0.1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text("MANUAL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 16),
                const Text("Start Empty\nWorkout", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("Track sets, reps & weight", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Color(0xFF0F766E), size: 20),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAICard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.deepPurple.shade600]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("SMART WORKOUT PLANNER", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              Icon(Icons.auto_awesome, color: Colors.purple.shade400, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Generate Plan", style: TextStyle(color: Color(0xFF233036), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text("Personalized routing powered by SMASH FIT", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.3)),
        ],
      ),
    );
  }

Widget _buildActivePlanCard(BuildContext context, WorkoutQuestionnaireController controller, WorkoutPlan plan) {
  final int routineLength = plan.weeklyRoutine?.length ?? 1;
  final int currentRoutineIndex = controller.currentDayIndex % routineLength;
  final nextDay = plan.weeklyRoutine?[currentRoutineIndex];

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple.shade400, size: 14),
                    const SizedBox(width: 6),
                    Text("MY PROGRAM", style: TextStyle(color: Colors.purple.shade400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(plan.title, style: const TextStyle(color: Color(0xFF233036), fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.2)),
                if (nextDay != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: Colors.purple.shade50.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.fitness_center_rounded, color: Colors.purple.shade400, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text("Next Session: ${nextDay.dayName}", style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF233036), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => WorkoutRoadmapView(plan: plan, totalWeeks: plan.totalWeeks, daysPerWeek: plan.daysPerWeek),
                    ));
                  },
                  child: const Text("Go To Roadmap", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryFallback() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFF8F9FA), shape: BoxShape.circle),
            child: Icon(Icons.history_rounded, size: 40, color: Colors.grey.withAlpha(100)),
          ),
          const SizedBox(height: 16),
          const Text(
            "No workouts logged on this day", 
            style: TextStyle(color: Color(0xFF233036), fontWeight: FontWeight.bold, fontSize: 15) 
          ),
          const SizedBox(height: 4),
          const Text(
            "Tap 'Start Empty Workout' to break a sweat!", 
            style: TextStyle(color: Color(0xFF8B8B8B), fontSize: 12)
          ),
        ],
      ),
    );
  }
}

