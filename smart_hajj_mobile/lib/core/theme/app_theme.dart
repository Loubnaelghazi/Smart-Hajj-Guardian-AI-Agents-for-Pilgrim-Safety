import 'package:flutter/material.dart';

import '../../models/domain.dart';

class AppColors {
  static const ink = Color(0xFF07151C),
      green = Color(0xFF087A5B),
      background = Color(0xFFF4F6F5),
      muted = Color(0xFF526660),
      red = Color(0xFFAF2937);
  static Color risk(RiskLevel level) => switch (level) {
    RiskLevel.low => green,
    RiskLevel.medium => const Color(0xFF866000),
    RiskLevel.high => const Color(0xFFAB4B0B),
    RiskLevel.critical => red,
    RiskLevel.unknown => muted,
  };
}

ThemeData guardianTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    surface: Colors.white,
    error: AppColors.red,
  ),
  scaffoldBackgroundColor: AppColors.background,
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE3EAE6),
    thickness: 1,
    space: 24,
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.1,
      color: AppColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -.6,
      color: AppColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 17, height: 1.4, color: AppColors.ink),
    bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: AppColors.muted),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD5DFDA)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFFDDEFE6),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  ),
);
