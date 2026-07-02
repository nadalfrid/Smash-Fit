import 'package:flutter/material.dart';

class CalendarFilterPopover {
  /// Displays a compact, floating interactive calendar card overlay themed to Smash Fit.
  static Future<void> show({
    required BuildContext context,
    required DateTime initialStartDate,
    required DateTime initialEndDate,
    required Function(DateTime start, DateTime end) onDatesSelected,
  }) async {
    const Color smashFitTeal = Color(0xFF1E9E88);
    const Color smashFitPurple = Color(0xFF8B1FA9);

    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStartDate, end: initialEndDate),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      helpText: 'SELECT PERFORMANCE TIMELINE',
      
      // 🎯 THE DIRECT FORCE OVERRIDE: Forces the input fields to display and parse DD/MM/YYYY
      locale: const Locale('en', 'GB'), 

      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: smashFitTeal,           
              onPrimary: Colors.white,          
              surface: Colors.white,            
              onSurface: Color(0xFF1E293B),     
              secondary: smashFitTeal,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: smashFitPurple, 
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      onDatesSelected(pickedRange.start, pickedRange.end);
    }
  }
}