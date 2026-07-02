// lib/views/workout/widgets/input_cell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputCell extends StatelessWidget {
  final String hint;
  final String? value;
  final bool allowDecimals;
  final bool isCompleted; // NEW: Reacts to being checked off
  final Function(String) onChanged;

  const InputCell({
    super.key,
    required this.hint,
    this.value,
    this.allowDecimals = false,
    this.isCompleted = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.transparent : const Color(0xFFF3F4F6), // Cooler modern grey
        borderRadius: BorderRadius.circular(10), // Larger radius
      ),
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontWeight: FontWeight.w700, 
          fontSize: 15,
          color: isCompleted ? Colors.teal : Colors.black87, // Color shift when done
        ),
        inputFormatters: [
          allowDecimals
              ? FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              : FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
          contentPadding: const EdgeInsets.only(bottom: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}