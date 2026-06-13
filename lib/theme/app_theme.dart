import 'package:flutter/material.dart';

class AppTheme {
  // ─── Apple System Colors ───────────────────────────────────────────
  // Dark Theme Palette
  static const Color darkBg = Color(0xFF000000); // True Black
  static const Color darkSurface = Color(0xFF1C1C1E); // System Gray 6
  static const Color darkCard = Color(0xFF1C1C1E); // System Gray 6
  static const Color primary = Color(0xFF007AFF); // System Blue
  static const Color primaryLight = Color(0xFF5AC8FA); // System Teal

  // Keep a secondary alias for backward compatibility in screens
  static const Color secondary = Color(0xFF007AFF); // Same as primary

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93); // System Gray
  static const Color borderDark = Color(0xFF38383A); // System Gray 4
  static const Color cardBorderDark = Color(0xFF2C2C2E); // hairline на карточках

  // Light Theme Palette
  static const Color lightBg = Color(0xFFFFFFFF); // Stark White
  static const Color lightSurface = Color(0xFFF2F2F7); // System Gray 6 (light)
  static const Color lightCard = Color(0xFFF2F2F7);

  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF8E8E93); // System Gray
  static const Color borderLight = Color(0xFFD1D1D6); // System Gray 4 (light)
  static const Color cardBorderLight = Color(0xFFE5E5EA); // hairline на карточках

  // Status Colors (Apple HIG)
  static const Color success = Color(0xFF34C759); // System Green
  static const Color warning = Color(0xFFFF9500); // System Orange
  static const Color error = Color(0xFFFF3B30); // System Red

  // Мягкие фоны статусов (для плашек/баннеров: тёмная / светлая тема)
  static const Color successBgDark = Color(0xFF192A20);
  static const Color successBgLight = Color(0xFFEAF9EE);
  static const Color warningBgDark = Color(0xFF2A2113);
  static const Color warningBgLight = Color(0xFFFFF4E5);
  static const Color errorBgDark = Color(0xFF2A1618);
  static const Color errorBgLight = Color(0xFFFDECEC);

  // ─── Dark Theme ────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: darkSurface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimaryDark,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.37,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryDark,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.36,
        ),
        titleLarge: TextStyle(
          color: textPrimaryDark,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.26,
        ),
        titleMedium: TextStyle(
          color: textPrimaryDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryDark,
          fontSize: 17,
          fontWeight: FontWeight.normal,
          letterSpacing: -0.41,
        ),
        bodyMedium: TextStyle(
          color: textSecondaryDark,
          fontSize: 15,
          height: 1.33,
          letterSpacing: -0.24,
        ),
        labelLarge: TextStyle(
          color: textSecondaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderDark, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: const TextStyle(color: textSecondaryDark, fontSize: 15),
        labelStyle: const TextStyle(color: textSecondaryDark, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.24,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }

  // ─── Light Theme ───────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: lightSurface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimaryLight,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.37,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryLight,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.36,
        ),
        titleLarge: TextStyle(
          color: textPrimaryLight,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.26,
        ),
        titleMedium: TextStyle(
          color: textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.normal,
          letterSpacing: -0.41,
        ),
        bodyMedium: TextStyle(
          color: textSecondaryLight,
          fontSize: 15,
          height: 1.33,
          letterSpacing: -0.24,
        ),
        labelLarge: TextStyle(
          color: textSecondaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderLight, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: const TextStyle(color: textSecondaryLight, fontSize: 15),
        labelStyle: const TextStyle(color: textSecondaryLight, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.24,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}
