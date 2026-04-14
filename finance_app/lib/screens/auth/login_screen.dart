import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardShell()),
        );
      }
    } catch (error) {
      final message = error is Exception ? error.toString() : 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C3DEC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome Back',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E2D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue to FinSmart',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8A8A9E),
                ),
              ),
              const SizedBox(height: 54),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _FigmaInput(
                      label: 'EMAIL ADDRESS',
                      hint: 'name@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    _FigmaInput(
                      label: 'PASSWORD',
                      hint: '••••••••',
                      obscureText: true,
                      controller: _passwordController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 54),
              _FigmaButton(
                text: _isLoading ? 'Signing in...' : 'Sign In',
                onPressed: _isLoading ? () {} : _handleLogin,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF8A8A9E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, a1, a2) => const RegisterScreen(),
                          transitionsBuilder: (context, a1, a2, child) {
                            return FadeTransition(opacity: a1, child: child);
                          },
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4C3DEC),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FigmaInput extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController controller;

  const _FigmaInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8A8A9E),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEaeaef),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1E1E2D),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFFCACACA),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FigmaButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _FigmaButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF4C3DEC),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0x404C3DEC),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
