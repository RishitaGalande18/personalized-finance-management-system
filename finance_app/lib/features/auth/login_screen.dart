import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';
import '../navigation/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const SizedBox(height: 20),

              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Manage your finances smartly",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Email",
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                ),
              ),

              const SizedBox(height: 24),

             SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () async {
      print("Login button clicked");

      final success = await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      print("Login result: $success");

      if (success) {
        Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => const MainNavigation(),
  ),
);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login failed")),
        );
      }
    },
    child: const Text("Login"),
  ),
),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () async {
                  Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
                },
                child: const Text("Create Account"),
              )
            ],
          ),
        ),
      ),
    );
  }
}