import 'package:flutter/material.dart';
import '../models/diet_model.dart';
import '../controllers/diet_controller.dart';

class FoodDetailsView extends StatefulWidget {
  final String mealId;
  final Map<String, dynamic> ingredientData; 
  final DietController controller;
  final FoodItem? existingItem;
  final DateTime? specificTargetDate; // 🌟 NEW: Catch the date

  const FoodDetailsView({
    super.key,
    required this.mealId,
    required this.ingredientData,
    required this.controller,
    this.existingItem,
    this.specificTargetDate, // 🌟 NEW
  });

  @override
  State<FoodDetailsView> createState() => _FoodDetailsViewState();
}

class _FoodDetailsViewState extends State<FoodDetailsView> {
  late TextEditingController _amountController;
  late String _displayUnit;

  @override
  void initState() {
    super.initState();
    
    // Check if the source is USDA to set a sensible default amount
    bool isUSDA = widget.ingredientData['source'] == "USDA";

    _amountController = TextEditingController(
      text: widget.existingItem != null 
          ? widget.existingItem!.amount.toString() 
          : (isUSDA ? "100.0" : "1.0") // USDA defaults to 100 for easy 100g/ml mapping
    );

    _displayUnit = widget.existingItem != null 
        ? widget.existingItem!.unit 
        : (widget.ingredientData['unit'] ?? widget.ingredientData['serving'] ?? "serving");
  }

  // --- CRITICAL CALCULATION LOGIC ---
  num _calc(String key) {
    double baseValue = (widget.ingredientData[key] ?? 0).toDouble();
    double inputAmount = double.tryParse(_amountController.text) ?? 0.0;
    
    // USDA data is 'per 100'. We divide baseValue by 100 to get value per 1 unit, 
    // then multiply by user input.
    if (widget.ingredientData['source'] == "USDA") {
      return (baseValue / 100) * inputAmount;
    }

    // Kal API (Malaysia) is 'per serving/unit'. Multiplier is direct.
    return (baseValue * inputAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.existingItem != null ? "Edit Log" : "Confirm Details"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(widget.ingredientData['name']?.toUpperCase() ?? "", 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Quantity / Amount", 
                      border: OutlineInputBorder()
                    ),
                    onChanged: (val) => setState(() {}), 
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    _displayUnit, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  )
                ),
              ],
            ),
            const SizedBox(height: 30),
            _nutrientTile("Calories", "${_calc('calories').toInt()}", "kcal"),
            _nutrientTile("Protein", "${_calc('protein').toStringAsFixed(1)}", "g"),
            _nutrientTile("Carbs", "${_calc('carbs').toStringAsFixed(1)}", "g"),
            _nutrientTile("Fat", "${_calc('fat').toStringAsFixed(1)}", "g"),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () async {
                  // 🌟 CHECK: Did we get a historical date? If not, it's a "Today" log.
                  DateTime baseTargetDate = widget.specificTargetDate ?? DateTime.now();

                  final finalItem = FoodItem(
                    id: widget.existingItem?.id ?? '', 
                    externalId: widget.ingredientData['id'].toString(),
                    name: widget.ingredientData['name'],
                    mealCategory: widget.mealId,
                    calories: _calc('calories').toInt(),
                    protein: _calc('protein').toInt(),
                    carbs: _calc('carbs').toInt(),
                    fat: _calc('fat').toInt(),
                    amount: double.tryParse(_amountController.text) ?? 1.0,
                    unit: _displayUnit,
                    // 🌟 USE THE TARGET DATE HERE
                    timestamp: widget.existingItem?.timestamp ?? baseTargetDate,
                  );

                  if (widget.existingItem != null) {
                    await widget.controller.updateFood(finalItem);
                  } else {
                    await widget.controller.logFood(
                      widget.mealId, 
                      finalItem, 
                      targetDate: finalItem.timestamp, 
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context); 
                    if (widget.existingItem == null) Navigator.pop(context); 
                  }
                },
                child: Text(
                  widget.existingItem != null ? "UPDATE LOG" : "ADD TO DIARY", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _nutrientTile(String l, String v, String u) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 16)), 
          Text("$v $u", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
        ],
      ),
    );
  }
}