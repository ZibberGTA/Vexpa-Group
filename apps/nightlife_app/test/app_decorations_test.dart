import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/theme/app_colors.dart';
import 'package:nightlife_app/core/theme/app_decorations.dart';

void main() {
  group('AppDecorations.heroCard', () {
    test('matches venue hero card surface styling', () {
      final decoration = AppDecorations.heroCard;

      expect(
        decoration.borderRadius,
        BorderRadius.circular(AppDecorations.heroCardBorderRadius),
      );
      expect(decoration.color, AppDecorations.heroCardBackgroundColor);
      expect(
        decoration.border,
        Border.all(color: AppColors.primaryPink.withOpacity(0.82), width: 1.2),
      );
      expect(decoration.boxShadow, [
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
      ]);
    });
  });
}
