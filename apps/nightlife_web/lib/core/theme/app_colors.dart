import 'package:flutter/material.dart';

/// Vexda brand palette — aligned with the mobile app for future Firebase integration.
class AppColors {
  AppColors._();

  static const Color primaryPink = Color(0xFFFF2D95);
  static const Color primaryPurple = Color(0xFF9D28FF);
  static const Color deepPurple = Color(0xFF1A0B2E);
  static const Color background = Color(0xFF111218);
  static const Color surface = Color(0xFF181A22);
  static const Color white = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA8ACB8);

  static const Color surfaceElevated = Color(0xFF202232);
  static const Color card = Color(0xFF1D1F2D);
  static const Color border = Color(0xFF31274A);
  static const Color glassBorder = Color(0x33FFFFFF);

  /// Subtle gold accent for Tonight's Trails premium styling.
  static const Color trailGold = Color(0xFFD4AF37);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPink, primaryPurple],
  );

  static const LinearGradient heroGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x661A0B2E),
      Color(0x00111218),
    ],
  );

  /// Soft surface gradient for nested premium cards.
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E2030),
      Color(0xFF181A22),
    ],
  );
}
