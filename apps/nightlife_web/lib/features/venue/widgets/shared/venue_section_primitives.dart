import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Shared empty state for venue detail sections.
class VenueEmptyState extends StatelessWidget {
  const VenueEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.primaryPurple.withValues(alpha: 0.75)),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared loading skeleton for venue detail sections.
class VenueSectionLoading extends StatelessWidget {
  const VenueSectionLoading({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < lines; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ],
      ],
    );
  }
}

/// Premium glass wrapper for venue page sections.
class VenueSectionShell extends StatelessWidget {
  const VenueSectionShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.anchorKey,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: anchorKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
