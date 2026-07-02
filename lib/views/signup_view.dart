import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'main_layout.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordObscure = true; 

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  int _selectedAge = 18;
  Gender _selectedGender = Gender.male;
  ActivityLevel _selectedActivity = ActivityLevel.sedentary;

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_updateHealthPreview);
    _weightController.addListener(_updateHealthPreview);
  }

  // --- REFACTORED FOR MVC: Calls the controller instead of calculations ---
  void _updateHealthPreview() {
    Provider.of<AuthController>(context, listen: false).updateSignUpPreview(
      age: _selectedAge,
      weightStr: _weightController.text,
      heightStr: _heightController.text,
      genderName: _selectedGender.name,
      activityLevelName: _selectedActivity.name,
    );
  }

  // Pure UI Category Text formatting logic
  String _getBmiCategory(double bmi) {
    if (bmi <= 0) return "";
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25.0) return "Normal";
    if (bmi < 30.0) return "Overweight";
    return "Obese";
  }

  void _showTdeeBriefing() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFF2A9D8F)),
            SizedBox(width: 10),
            Text("What is TDEE?"),
          ],
        ),
        content: const Text(
          "TDEE stands for Total Daily Energy Expenditure. It is an estimation of how many calories your body burns per day based on your base metabolic clock speed, age, weight, height, and targeted functional movement activity selections.",
          style: TextStyle(fontSize: 15, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got It", style: TextStyle(color: Color(0xFF2A9D8F), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _confirmSignUp() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Sign Up"),
        content: const Text("Are you sure you want to construct your Smash Fit workout credentials and proceed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F)),
            onPressed: () {
              Navigator.pop(ctx);
              _submit(); 
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _submit() async {
    final authController = Provider.of<AuthController>(context, listen: false);

    bool success = await authController.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      age: _selectedAge,
      heightStr: _heightController.text.trim(),
      weightStr: _weightController.text.trim(),
      gender: _selectedGender,
      activityLevel: _selectedActivity,
    );

    if (mounted) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage ?? "An error occurred during account registration."), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orangeAccent;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_nameController, "Full Name", Icons.person),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedAge,
                      decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder()),
                      items: List.generate(80, (i) => i + 12).map((age) => DropdownMenuItem(value: age, child: Text(age.toString()))).toList(),
                      onChanged: (val) {
                        _selectedAge = val!;
                        _updateHealthPreview();
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<Gender>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: Gender.male, child: Text("Male")),
                        DropdownMenuItem(value: Gender.female, child: Text("Female")),
                      ],
                      onChanged: (val) {
                        _selectedGender = val!;
                        _updateHealthPreview();
                      },
                    ),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              
              _buildTextField(_weightController, "Weight (kg)", Icons.monitor_weight, isNumber: true),
              const SizedBox(height: 15),
              _buildTextField(_heightController, "Height (cm)", Icons.height, isNumber: true),
              const SizedBox(height: 15),

              DropdownButtonFormField<ActivityLevel>(
                value: _selectedActivity,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Activity Level", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_run, color: Color(0xFF2A9D8F)),
                ),
                // --- REFACTORED FOR MVC: Uses centralized Model layer .description text helper extension ---
                items: ActivityLevel.values.map((level) => DropdownMenuItem(
                  value: level, 
                  child: Text(
                    level.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedActivity = val!;
                    _updateHealthPreview();
                  });
                },
              ),
              const SizedBox(height: 25),

              // --- REFACTORED FOR MVC: Listening explicitly to controller state values via Consumer ---
              Consumer<AuthController>(
                builder: (context, authController, child) {
                  if (authController.signUpBmi <= 0) return const SizedBox.shrink();
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.shade100)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("BMI", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(authController.signUpBmi.toString(), style: TextStyle(fontSize: 20, color: _getBmiColor(authController.signUpBmi), fontWeight: FontWeight.bold)),
                            Text(
                              _getBmiCategory(authController.signUpBmi), 
                              style: TextStyle(fontSize: 13, color: _getBmiColor(authController.signUpBmi), fontWeight: FontWeight.w600)
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Maintenance TDEE", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: _showTdeeBriefing,
                                  child: const Icon(Icons.info_outline, size: 16, color: Colors.teal),
                                ),
                              ],
                            ),
                            Text("${authController.signUpTdee.toInt()} kcal", style: const TextStyle(fontSize: 20, color: Colors.teal, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),
              _buildTextField(_emailController, "Email", Icons.email),
              const SizedBox(height: 15),
              
              _buildTextField(
                _passwordController, 
                "Password", 
                Icons.lock, 
                isPassword: true,
                obscureText: _isPasswordObscure,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordObscure = !_isPasswordObscure;
                  });
                }
              ),
              
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Password requirements:",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "• Minimum 8 characters long\n• At least 1 uppercase letter (A-Z)\n• At least 1 lowercase letter (a-z)\n• At least 1 numeric digit (0-9)\n• At least 1 special character (!@#\$%^&*)",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Consumer<AuthController>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _confirmSignUp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50), 
                      backgroundColor: const Color(0xFF2A9D8F)
                    ),
                    child: authProvider.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 16)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, {
    bool isPassword = false, 
    bool isNumber = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))] : [],
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon), 
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleVisibility,
              )
            : null,
        border: const OutlineInputBorder()
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return "$label is required";
        if (label == "Email" && !val.contains("@")) return "Enter a valid email address";
        
        if (isPassword) {
          if (val.length < 8) return "Password must be at least 8 characters long";
          if (!val.contains(RegExp(r'[A-Z]'))) return "Must contain at least 1 uppercase letter";
          if (!val.contains(RegExp(r'[a-z]'))) return "Must contain at least 1 lowercase letter";
          if (!val.contains(RegExp(r'[0-9]'))) return "Must contain at least 1 numeric digit";
          if (!val.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_]'))) return "Must contain at least 1 special character";
        }
        return null;
      },
    );
  }
}