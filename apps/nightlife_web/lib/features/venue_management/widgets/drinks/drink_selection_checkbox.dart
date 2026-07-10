import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/premium_effects.dart';

/// Compact square checkbox for drinks list selection.
class DrinkSelectionCheckbox extends StatelessWidget {
  const DrinkSelectionCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      checked: value,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: value ? 1.05 : 1,
            duration: PremiumEffects.fast,
            curve: PremiumEffects.easeOut,
            child: AnimatedContainer(
              duration: PremiumEffects.fast,
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: value ? AppColors.brandGradient : null,
                color: value
                    ? null
                    : AppColors.surfaceElevated.withValues(alpha: 0.72),
                border: Border.all(
                  color: value
                      ? Colors.transparent
                      : AppColors.primaryPurple.withValues(alpha: 0.32),
                ),
                boxShadow: value ? PremiumEffects.hoverGlow(intensity: 0.35) : null,
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
