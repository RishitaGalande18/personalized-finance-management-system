import 'package:flutter/material.dart';

/// App color palette — premium light finance theme
class AppColors {
  AppColors._();

  // ── Primary ──
  static const Color primary = Color(0xFF102A6A); // Navy blue
  static const Color primaryLight = Color(0xFF3755A3);
  static const Color primaryDark = Color(0xFF091A3C);

  // ── Background & Surfaces ──
  static const Color background = Color(0xFFF8F9FB); // Clean off-white
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderSoft = Color(0xFFEAEAEE);

  // ── Indicator Cards ──
  // Income (Green)
  static const Color incomeBg = Color(0xFFDAF6E4);
  static const Color incomeText = Color(0xFF2E7D32);
  
  // Expenses (Orange)
  static const Color expenseBg = Color(0xFFFFE8D1);
  static const Color expenseText = Color(0xFFE67E22);
  
  // Savings (Violet)
  static const Color savingsBg = Color(0xFFE8E7FF);
  static const Color savingsText = Color(0xFF4C3DEC);

  // ── Text ──
  static const Color textPrimary = Color(0xFF1E1E2D); // Deep Navy/Charcoal
  static const Color textSecondary = Color(0xFF8A8A9E); // Soft Slate
  static const Color textMuted = Color(0xFFCACACA);

  // ── Semantic ──
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // ── Chart Colors ──
  static const List<Color> chartColors = [
    Color(0xFF5C61F2), // Main Blue/Violet
    Color(0xFFF39C12), // Orange
    Color(0xFF2ECC71), // Green
    Color(0xFFFF7675), // Soft Red
  ];

  // ── Legacy / Dark-theme aliases ──
  static const Color bgDark = Color(0xFF1A1A2E);
  static const Color bgCard = Color(0xFF22223A);
  static const Color bgInput = Color(0xFF2A2A40);
  static const Color surfaceLight = Color(0xFF32324A);
  static const Color surface = Color(0xFF22223A);
  static const Color textHint = Color(0xFF6C6C80);

  // ── Accents ──
  static const Color accent = Color(0xFF6F7DF2);
  static const Color accentPink = Color(0xFFFF6B81);
  static const Color accentOrange = Color(0xFFF39C12);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF102A6A), Color(0xFF3755A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0F1D41), Color(0xFF102A6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ──
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
