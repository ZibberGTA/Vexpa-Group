import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      splashColor: AppColors.primaryPink.withValues(alpha: 0.10),
      highlightColor: AppColors.primaryPurple.withValues(alpha: 0.08),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPink,
        secondary: AppColors.primaryPurple,
        surface: AppColors.surface,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: AppColors.primaryPurple.withValues(alpha: 0.20),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: AppColors.primaryPurple.withValues(alpha: 0.20),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ).copyWith(
        headlineLarge: const TextStyle(
          color: AppColors.white,
          fontSize: 56,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          height: 1.05,
        ),
        headlineMedium: const TextStyle(
          color: AppColors.white,
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.1,
        ),
        headlineSmall: const TextStyle(
          color: AppColors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: const TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 18,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 1.45,
        ),
        labelLarge: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
