import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0D631B);
  static const onPrimary = Colors.white;
  static const primaryContainer = Color(0xFF2E7D32);
  static const onPrimaryContainer = Color(0xFFCBFFC2);
  static const secondary = Color(0xFF3C6842);
  static const secondaryContainer = Color(0xFFBDEFBE);
  static const onSecondaryContainer = Color(0xFF426E47);
  static const surface = Color(0xFFFBF9F1);
  static const surfaceContainer = Color(0xFFEFEEE5);
  static const surfaceContainerLow = Color(0xFFF5F4EB);
  static const surfaceContainerLowest = Colors.white;
  static const surfaceContainerHigh = Color(0xFFEAE8E0);
  static const onSurface = Color(0xFF1B1C17);
  static const onSurfaceVariant = Color(0xFF40493D);
  static const outline = Color(0xFF707A6C);
  static const outlineVariant = Color(0xFFBFCABA);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
}

class AppTextStyles {
  static const displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 57,
    height: 64 / 57,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w400,
  );

  static const headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w600,
  );

  static const headlineMediumMobile = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w600,
  );

  static const titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w500,
  );

  static const bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.25,
    fontWeight: FontWeight.w400,
  );

  static const labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
  );

  static const labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
  );
}