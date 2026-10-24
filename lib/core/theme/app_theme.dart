import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores centralizada CampJu (sección 0.2)
  static const Color primary = Color(0xFF1F4D3A);
  static const Color primaryDark = Color(0xFF143527);
  static const Color primaryContainer = Color(0xFFDCEBE2);
  static const Color secondary = Color(0xFFC8781E);
  static const Color accent = Color(0xFFE0A526);
  static const Color background = Color(0xFFF6F4EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1B1F1D);
  static const Color onSurfaceMuted = Color(0xFF5F6B65);
  static const Color error = Color(0xFFB3261E);
  static const Color like = Color(0xFFD6336C);
  static const Color border = Color(0xFFE2E0D8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
    );
  }
}
