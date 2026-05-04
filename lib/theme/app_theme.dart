import 'package:flutter/material.dart';

class AppTheme {
  // IBM Brand Colors
  static const Color ibmBlue = Color(0xFF0F62FE);
  static const Color ibmDarkBlue = Color(0xFF002D9C);
  static const Color ibmLightBlue = Color(0xFF78A9FF);
  static const Color ibmGray = Color(0xFF525252);
  static const Color ibmLightGray = Color(0xFFF4F4F4);
  static const Color ibmBorderGray = Color(0xFFC6C6C6);
  static const Color ibmDivider = Color(0xFFE0E0E0);
  static const Color ibmBlack = Color(0xFF161616);
  static const Color ibmWhite = Color(0xFFFFFFFF);
  static const Color ibmHeaderBlack = Color(0xFF161616);
  static const Color ibmHintGray = Color(0xFF8D8D8D);

  // Accent colors
  static const Color ibmTeal = Color(0xFF009D9A);
  static const Color ibmPurple = Color(0xFF8A3FFC);
  static const Color ibmGreen = Color(0xFF24A148);

  static ThemeData lightTheme = ThemeData(
    primaryColor: ibmBlue,
    scaffoldBackgroundColor: ibmWhite,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: ibmBlue,
      primary: ibmBlue,
      secondary: ibmTeal,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ibmBlue,
        foregroundColor: ibmWhite,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: ibmBorderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: ibmBorderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: ibmBlue, width: 2),
      ),
      hintStyle: const TextStyle(color: ibmHintGray, fontSize: 14),
    ),
  );
}
