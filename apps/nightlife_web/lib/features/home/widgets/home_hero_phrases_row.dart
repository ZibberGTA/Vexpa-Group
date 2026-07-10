import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Static marketing phrase row below the hero search bar.
class HomeHeroPhrasesRow extends StatelessWidget {
  const HomeHeroPhrasesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < AppStrings.homeHeroPhrases.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 14,
              color: AppColors.primaryPurple.withValues(alpha: 0.35),
            ),
          Text(
            AppStrings.homeHeroPhrases[i],
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.92),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
