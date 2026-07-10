import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PillTag extends StatelessWidget {
  const PillTag({
    super.key,
    required this.label,
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryPurple.withValues(alpha: 0.22)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.primaryPurple.withValues(alpha: 0.55)
              : AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? AppColors.white : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
