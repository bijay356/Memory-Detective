import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color background = Color(0xFF0A101E);
  static const Color surface = Color(0xFF141E34);
  static const Color surfaceLight = Color(0xFF1E2B4A);

  static const Color gold = Color(0xFFFFC107);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenDark = Color(0xFF2E7D32);
  static const Color purple = Color(0xFF651FFF);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: gold,
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge:
            GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium:
            GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge:
            GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium:
            GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: green,
        surface: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: background,
          textStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
