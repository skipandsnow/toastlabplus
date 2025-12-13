import 'package:flutter/material.dart';

/// Ghibli-inspired Theme for ToastLabPlus (Production Refined)
/// "Cozy, warm, gentle, and emotionally calming"
class AppTheme {
  // Muted Pastel Palette (Production Ghibli)
  // Low saturation, avoid candy-like colors

  static const _sageGreen = Color(0xFF8FA893); // Sage Green (Primary)
  static const _dustyBlue = Color(0xFF93B4C3); // Dusty Blue (Secondary)
  static const _softPeach = Color(0xFFEAC8B6); // Soft Peach (Accent)

  static const _ricePaper = Color(0xFFFDFBF7); // Cream / Rice Paper Base
  static const _warmWhite = Color(0xFFFFFFFF); // Pure White (for contrast)

  static const _darkWood = Color(0xFF4A4036); // Dark Wood Brown (Text)
  static const _lightWood = Color(0xFF8D7B68); // Light Wood Brown (Sub-text)

  static const _softYellow = Color(0xFFF9F1D0); // Muted Sun (Highlights)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'NotoSansTC',
      colorScheme: const ColorScheme.light(
        primary: _sageGreen,
        secondary: _dustyBlue,
        tertiary: _softPeach,
        surface: _ricePaper,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _darkWood,
      ),
      scaffoldBackgroundColor: _ricePaper,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _darkWood,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkWood,
          letterSpacing: 0.5,
        ),
      ),
      // ... keep other themes if needed, but we mostly use custom widgets
    );
  }

  // Getters for specific usage
  static Color get sageGreen => _sageGreen;
  static Color get dustyBlue => _dustyBlue;
  static Color get softPeach => _softPeach;
  static Color get ricePaper => _ricePaper;
  static Color get warmWhite => _warmWhite;
  static Color get darkWood => _darkWood;
  static Color get lightWood => _lightWood;
  static Color get softYellow => _softYellow;
}
