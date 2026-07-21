import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared surface decorations used across Vexda mobile surfaces.
class AppDecorations {
  const AppDecorations._();

  static const double heroCardBorderRadius = 28;

  static const Color heroCardBackgroundColor = Color(0xB3111218);

  /// Venue hero card and Discover results panel share this surface treatment.
  static BoxDecoration get heroCard => BoxDecoration(
    color: heroCardBackgroundColor,
    borderRadius: BorderRadius.circular(heroCardBorderRadius),
    border: Border.all(
      color: AppColors.primaryPink.withOpacity(0.82),
      width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryPink.withOpacity(0.18),
        blurRadius: 26,
        offset: const Offset(0, -6),
      ),
      const BoxShadow(
        color: Color(0xAA000000),
        blurRadius: 28,
        offset: Offset(0, 14),
      ),
    ],
  );
}
