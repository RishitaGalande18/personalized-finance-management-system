import 'package:flutter/material.dart';
// Note: Keeping app_theme.dart available but overriding to Light for these specific UI designs
import 'screens/auth/splash_screen.dart';

void main() {
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinSmart',
      debugShowCheckedModeBanner: false,
      // Switching to a pristine light theme to match the Figma screenshots
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4C3DEC),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
