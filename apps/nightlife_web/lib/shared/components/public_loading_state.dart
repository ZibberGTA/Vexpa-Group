import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Shared loading indicator for public platform pages.
class PublicLoadingState extends StatelessWidget {
  const PublicLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryPink),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton block for public page loading layouts.
class PublicSkeletonBlock extends StatelessWidget {
  const PublicSkeletonBlock({
    super.key,
    this.height = 56,
    this.width,
  });

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }
}
