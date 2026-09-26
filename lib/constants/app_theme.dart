import 'package:flutter/material.dart';

/// Centralized Design System & Theme for Maktabat Sheikh Abdul Salam Al-Rustami.
/// Theme: Imperial Burgundy / Deep Wine & Burnished Gold (شاہی عنابی و زریں سنہرا)
class AppTheme {
  // Primary Imperial Burgundy Palette
  static const Color primary = Color(0xFF3A0F18);
  static const Color primaryLight = Color(0xFF541926);
  static const Color primaryDark = Color(0xFF24070D);

  // Burnished Antique Gold Palette
  static const Color accent = Color(0xFFC99B3B);
  static const Color accentLight = Color(0xFFF3E2C4);
  static const Color accentMuted = Color(0xFFDFBA6D);

  // Background & Surface
  static const Color background = Color(0xFFF8F5F0);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0x0F000000);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1E1718);
  static const Color textSecondary = Color(0xFF6E6365);
  static const Color textLight = Colors.white;

  // Rich Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [primary, primaryLight, primaryDark],
  );

  static const LinearGradient cardAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A1521), Color(0xFF2C0A12)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
  );

  // Material 3 ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Amiri',
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: const Color(0xFFEFE9E0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          fontFamily: 'Amiri',
          color: primary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
