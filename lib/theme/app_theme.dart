import 'package:flutter/material.dart';

class AppTheme {
  // Dice/casino-inspired palette
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color feltGreen = Color(0xFF2E7D32);
  static const Color accentGold = Color(0xFFFFB300);
  static const Color accentRed = Color(0xFFC62828);
  static const Color cardCream = Color(0xFFFFF8E1);
  static const Color darkBg = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceCard = Color(0xFF2A2A2A);

  // Category colors for scoring buttons
  static const Color singlesColor = Color(0xFF1565C0);     // Blue
  static const Color threeColor = Color(0xFF2E7D32);       // Green
  static const Color fourColor = Color(0xFF6A1B9A);        // Purple
  static const Color fiveColor = Color(0xFFE65100);        // Deep Orange
  static const Color sixColor = Color(0xFFC62828);         // Red
  static const Color specialColor = Color(0xFF00695C);     // Teal

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accentGold,
        secondary: feltGreen,
        surface: surfaceDark,
        error: accentRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: darkBg,
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: accentGold,
        elevation: 4,
        centerTitle: true,
        toolbarHeight: 56,
        titleTextStyle: TextStyle(
          color: accentGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentGold),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentGold, width: 2),
        ),
        labelStyle: const TextStyle(color: accentGold),
      ),
    );
  }
}
