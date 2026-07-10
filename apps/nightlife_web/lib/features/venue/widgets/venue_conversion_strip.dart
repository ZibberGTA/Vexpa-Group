import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/widgets/glass_container.dart';
import '../models/venue_details_view.dart';

/// Guides users toward the venue page primary conversions.
class VenueConversionStrip extends StatelessWidget {
  const VenueConversionStrip({
    super.key,
    required this.venue,
  });

  final VenueDetailsView venue;

  Future<void> _openDirections(BuildContext context) async {
    if (!venue.hasCoordinates) {
      _showSnack(context, 'Directions coming soon for this venue');
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${venue.latitude},${venue.longitude}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showSnack(context, 'Could not open directions');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready for tonight?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Get directions, save this venue, or take Vexda with you on mobile.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              DrinkSpotButton(
                label: 'Get directions',
                icon: Icons.directions_outlined,
                variant: DrinkSpotButtonVariant.primary,
                compact: true,
                onPressed: () => _openDirections(context),
              ),
              DrinkSpotButton(
                label: 'Save venue',
                icon: Icons.bookmark_border_rounded,
                variant: DrinkSpotButtonVariant.secondary,
                compact: true,
                onPressed: () => _showSnack(context, 'Save venue coming soon'),
              ),
              DrinkSpotButton(
                label: 'View on map',
                icon: Icons.map_outlined,
                variant: DrinkSpotButtonVariant.ghost,
                compact: true,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.search);
                },
              ),
              DrinkSpotButton(
                label: AppStrings.downloadApp,
                icon: Icons.phone_iphone_rounded,
                variant: DrinkSpotButtonVariant.ghost,
                compact: true,
                onPressed: () => _showSnack(context, 'App download coming soon'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
