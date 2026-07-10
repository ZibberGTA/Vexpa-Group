import 'package:flutter/material.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layouts/content_container.dart';

/// Reusable hero header for public marketing and browse pages.
class PublicPageHero extends StatelessWidget {
  const PublicPageHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return ContentContainer(
      child: Padding(
        padding: EdgeInsets.only(
          top: isMobile ? AppSpacing.xl : AppSpacing.xxxl,
          bottom: isMobile ? AppSpacing.xl : AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: TextStyle(
                color: AppColors.primaryPink.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: isMobile ? 34 : 48,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(height: AppSpacing.xl),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
