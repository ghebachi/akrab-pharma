import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF1E3B8B);   // Navy Blue
  static const Color accent  = Color(0xFF10B981);   // Emerald Green

  // Neutrals
  static const Color background   = Color(0xFFF8FAFC);
  static const Color surface      = Colors.white;
  static const Color textPrimary  = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color divider      = Color(0xFFE2E8F0);

  // Semantic
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = accent;

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: primary,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
