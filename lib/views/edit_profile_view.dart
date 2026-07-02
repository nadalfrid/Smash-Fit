import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';
import '../services/health_service.dart';

class EditProfileView extends StatefulWidget {
  final UserModel user;
  const EditProfileView({super.key, required this.user});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  // State Variables
  late int _selectedAge;
  late Gender _selectedGender;
  late ActivityLevel _selectedActivity;

  // Live Preview Variables
  double _liveBmi = 0.0;
  double _liveTdee = 0.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _weightController = TextEditingController(text: widget.user.weight.toString());
    _heightController = TextEditingController(text: widget.user.height.toString());
    _selectedAge = widget.user.age;
    _selectedGender = widget.user.gender;
    _selectedActivity = widget.user.activityLevel;

    _updateHealthPreview();

    _weightController.addListener(_updateHealthPreview);
    _heightController.addListener(_updateHealthPreview);
  }

  void _updateHealthPreview() {
    double w = double.tryParse(_weightController.text) ?? 0;
    double h = double.tryParse(_heightController.text) ?? 0;

    setState(() {
      _liveBmi = HealthService.calculateBMI(w, h);
      _liveTdee = HealthService.calculateTDEE(
        age: _selectedAge,
        weight: w,
        height: h,
        gender: _selectedGender.name,
        activityLevel: _selectedActivity.name,
      );
    });
  }

  // 🌟 DIALOG FACTORY #1: Discard Edits Safety Confirmation Prompts
  void _showDiscardConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Discard Changes?"),
          ],
        ),
        content: const Text("You have unsaved adjustments in your profile form layout. Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Editing", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close Dialog
              Navigator.pop(context); // Exit Screen back to ProfileView
            },
            child: const Text("Discard", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 🌟 DIALOG FACTORY #2: Database Submission Gate Confirmation Prompts
  void _showSaveConfirmation() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: Colors.teal),
            SizedBox(width: 10),
            Text("Save Changes?"),
          ],
        ),
        content: const Text("Your macro metrics, calorie targets, and dynamic metrics targets will re-calculate matching these modifications."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.pop(ctx); // Close Dialog
              _executeProfileUpdate(); // Invoke Database Service Worker Thread
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _executeProfileUpdate() async {
    setState(() => _isLoading = true);

    try {
      await AuthController().updateProfile(
        name: _nameController.text.trim(),
        age: _selectedAge,
        heightStr: _heightController.text.trim(),
        weightStr: _weightController.text.trim(),
        gender: _selectedGender,
        activityLevel: _selectedActivity,
      );

      if (mounted) {
        Navigator.pop(context); // Go back to ProfileView
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving modifications: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatActivityLevel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary: return "Sedentary: Little or no exercise";
      case ActivityLevel.light: return "Light: Exercise 1-3 times/week";
      case ActivityLevel.moderate: return "Moderate: Exercise 4-5 times/week";
      case ActivityLevel.active: return "Active: Daily or intense 3-4 times/week";
      case ActivityLevel.veryActive: return "Very Active: Intense exercise 6-7 times/week";
      case ActivityLevel.extraActive: return "Extra Active: Very intense or physical job";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 POP SCOPE: Catches OS Back Navigation swipe gestures or hardware buttons cleanly
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showDiscardConfirmation(); 
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Profile"),
          centerTitle: true, // 🌟 FORCE TITLE TO BE PERFECTLY CENTERED
          // 🌟 PHASE 1: Text cancel button with custom padding layout alignment
          leadingWidth: 90,
          leading: TextButton(
            onPressed: _isLoading ? null : _showDiscardConfirmation,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              "Cancel", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          // 🌟 PHASE 2: Top Right Actions completely emptied to prevent duplicate lifecycle paths
          actions: const [],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_nameController, "Full Name", Icons.person),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedAge,
                        decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder()),
                        items: List.generate(80, (i) => i + 12).map((age) => DropdownMenuItem(value: age, child: Text(age.toString()))).toList(),
                        onChanged: (val) {
                          setState(() { _selectedAge = val!; _updateHealthPreview(); });
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: DropdownButtonFormField<Gender>(
                        value: _selectedGender,
                        decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                        items: Gender.values.map((g) => DropdownMenuItem(value: g, child: Text(g.name.toUpperCase()))).toList(),
                        onChanged: (val) {
                          setState(() { _selectedGender = val!; _updateHealthPreview(); });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildTextField(_weightController, "Weight (kg)", Icons.monitor_weight, isNumber: true),
                const SizedBox(height: 20),
                _buildTextField(_heightController, "Height (cm)", Icons.height, isNumber: true),
                const SizedBox(height: 20),

                DropdownButtonFormField<ActivityLevel>(
                  value: _selectedActivity,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Activity Level", border: OutlineInputBorder()),
                  items: ActivityLevel.values.map((level) => DropdownMenuItem(
                    value: level,
                    child: Text(_formatActivityLevel(level), style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (val) {
                    setState(() { _selectedActivity = val!; _updateHealthPreview(); });
                  },
                ),

                const SizedBox(height: 30),

                _buildPreviewCard(),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _showSaveConfirmation,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPreviewItem("BMI", _liveBmi.toStringAsFixed(1), Icons.speed),
          _buildPreviewItem("TDEE", "${_liveTdee.toInt()} kcal", Icons.local_fire_department),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))] : [],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }
}