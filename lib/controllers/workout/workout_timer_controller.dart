import 'dart:async';
import 'package:flutter/material.dart';

class WorkoutTimerController extends ChangeNotifier {
  Timer? _timer;
  Duration duration = Duration.zero;
  DateTime? startTime;

  void startTimer() {
    startTime = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      duration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void stopTimer() {
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    duration = Duration.zero;
    startTime = null;
    notifyListeners();
  }

  void loadExistingDuration(DateTime start, DateTime? end) {
    _timer?.cancel();
    startTime = start;
    duration = end?.difference(start) ?? Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}