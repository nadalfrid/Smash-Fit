import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../controllers/report_controller.dart'; // Import to access TrendMetric

class PdfExportService {
  Future<Uint8List> generateReport({
    required String timeframeText,
    required String activeGoal, // Added the contextual goal
    required TrendMetric weightTrend, 
    required TrendMetric bmiText,
    required TrendMetric avgCal, 
    required TrendMetric macroConsistency,
    required TrendMetric totalVolume, 
    required TrendMetric totalSets, 
    required TrendMetric mostTrained,
    required bool includeWeightTrend, 
    required bool includeBmiTrack,
    required bool includeCalories, 
    required bool includeMacros,
    required bool includeTotalVolume, 
    required bool includeTotalSets, 
    required bool includeMuscleGroup,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(timeframeText, activeGoal),
            pw.SizedBox(height: 20),
            
            if (includeWeightTrend || includeBmiTrack) 
              _buildBodyStatsSection(weightTrend, bmiText, includeWeightTrend, includeBmiTrack),
              
            if (includeCalories || includeMacros) 
              _buildNutritionSection(avgCal, macroConsistency, includeCalories, includeMacros),
              
            if (includeTotalVolume || includeTotalSets || includeMuscleGroup) 
              _buildTrainingSection(totalVolume, totalSets, mostTrained, includeTotalVolume, includeTotalSets, includeMuscleGroup),
          ];
        },
      ),
    );
    return pdf.save();
  }

  pw.Widget _buildHeader(String timeframeText, String activeGoal) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("SMASH FIT", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#008080'))),
        pw.Text("Progress Report", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text("Timeframe: $timeframeText", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.Text("Primary Goal: $activeGoal", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.SizedBox(height: 12),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildBodyStatsSection(TrendMetric trend, TrendMetric bmi, bool showTrend, bool showBmi) {
    List<List<String>> data = [];
    if (showTrend) data.add(['Weight Composition', trend.baseline, trend.current]);
    if (showBmi) data.add(['BMI Status Track', bmi.baseline, bmi.current]);
    return _buildSectionLayout(title: "Body Composition", tableData: data);
  }

  pw.Widget _buildNutritionSection(TrendMetric cal, TrendMetric macro, bool showCal, bool showMacro) {
    List<List<String>> data = [];
    if (showCal) data.add(['Avg Daily Calories', cal.baseline, cal.current]);
    if (showMacro) data.add(['Macro Consistency', macro.baseline, macro.current]);
    return _buildSectionLayout(title: "Nutrition Overview", tableData: data);
  }

  pw.Widget _buildTrainingSection(TrendMetric vol, TrendMetric sets, TrendMetric muscle, bool showVol, bool showSets, bool showMuscle) {
    List<List<String>> data = [];
    if (showVol) data.add(['Total Training Volume', vol.baseline, vol.current]);
    if (showSets) data.add(['Total Sets Completed', sets.baseline, sets.current]);
    if (showMuscle) data.add(['Most Trained Muscle', muscle.baseline, muscle.current]);
    return _buildSectionLayout(title: "Training Metrics", tableData: data);
  }

  pw.Widget _buildSectionLayout({required String title, required List<List<String>> tableData}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Metric Parameter', 'Baseline (Start)', 'Current Peak (End)'], // 3-Column Matrix!
          data: tableData,
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
          cellHeight: 30,
        ),
        pw.SizedBox(height: 25),
      ],
    );
  }
}