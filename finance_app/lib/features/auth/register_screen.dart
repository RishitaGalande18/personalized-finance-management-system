import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    final success = await ApiService.register(
      nameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful')),
        );
        Navigator.pop(context);
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your profile and manage your money securely.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              _buildInput(
                controller: nameController,
                hintText: 'Full Name',
                labelText: 'Name',
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: emailController,
                hintText: 'name@example.com',
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: passwordController,
                hintText: 'Create a password',
                labelText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : registerUser,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(color: AppColors.textMuted),
        hintStyle: TextStyle(color: AppColors.textMuted.withAlpha(180)),
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
