import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';

/// Error state when the venue dashboard cannot load Firestore data.
class VenueDashboardErrorPanel extends StatelessWidget {
  const VenueDashboardErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
    this.embedded = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final panel = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: EdgeInsets.all(embedded ? AppSpacing.lg : AppSpacing.xxl),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard unavailable',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.5,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                DrinkSpotButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (embedded) return panel;

    return PublicPageShell(child: panel);
  }
}
