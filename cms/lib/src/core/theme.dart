import 'package:flutter/material.dart';

/// CMS Design System — dark admin theme
class CmsTheme {
  const CmsTheme._();

  // Background layers
  static const Color bg = Color(0xFF0F1117);
  static const Color sidebar = Color(0xFF161B25);
  static const Color surface = Color(0xFF1C2333);
  static const Color surfaceElevated = Color(0xFF232B3E);

  // Border
  static const Color border = Color(0xFF252D3D);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Accent / brand
  static const Color accent = Color(0xFF6366F1); // Indigo
  static const Color accentLight = Color(0xFF818CF8);

  // Status colours
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.dark(
      primary: accent,
      secondary: accentLight,
      surface: surface,
      error: danger,
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 28,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      bodyLarge: TextStyle(color: textSecondary, fontSize: 14),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
      labelLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: accent),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: danger),
      ),
      labelStyle: const TextStyle(color: textSecondary, fontFamily: 'Inter'),
      hintStyle: const TextStyle(color: textMuted, fontFamily: 'Inter'),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
  );
}
