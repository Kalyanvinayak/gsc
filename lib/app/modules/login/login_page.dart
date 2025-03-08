import 'package:flutter/material.dart';
import '../../central/modules/dashboard/dashboard_page.dart' as central;
// Remove state import for now
// import '../../state/modules/dashboard/dashboard_page.dart' as state;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = "Central Government"; // Default selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "GOVERNMENT LOGIN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Dropdown for selecting role
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedRole,
                  dropdownColor: Colors.black,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  isExpanded: true,
                  underline: Container(),
                  items:
                      ["Central Government", "State Government"].map((
                        String role,
                      ) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            role,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 15),

              _buildTextField(emailController, "Email"),
              const SizedBox(height: 15),
              _buildTextField(passwordController, "Password", isPassword: true),
              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () {
                  if (selectedRole == "Central Government") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const central.CentralDashboardPage(),
                      ),
                    );
                  } else {
                    // TEMPORARY FIX: Show a message instead of navigating to a non-existent page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "State Government module is under development.",
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text(
                  "LOGIN",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}
