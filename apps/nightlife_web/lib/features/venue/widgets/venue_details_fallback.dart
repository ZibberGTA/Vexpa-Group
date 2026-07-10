import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';

/// Fallback when a venue cannot be loaded from Firestore.
class VenueDetailsFallback extends StatelessWidget {
  const VenueDetailsFallback({
    super.key,
    this.message = 'This venue could not be loaded right now.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 48,
                color: AppColors.primaryPurple.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Venue unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              DrinkSpotButton(
                label: 'Back to search',
                variant: DrinkSpotButtonVariant.primary,
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.search,
                    (route) => route.settings.name == AppRouter.home,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
