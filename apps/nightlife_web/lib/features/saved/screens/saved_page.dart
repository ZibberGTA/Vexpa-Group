import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_empty_state.dart';
import '../../../shared/components/public_page_hero.dart';
import '../../../shared/components/section_header.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';

/// Desktop saved page — architecture for venues, trails and events.
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      navActiveRoute: AppRouter.saved,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PublicPageHero(
            eyebrow: 'Your collection',
            title: AppStrings.savedTitle,
            subtitle: AppStrings.savedSubtitle,
          ),
          ContentContainer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PublicEmptyState(
                    icon: Icons.login_rounded,
                    title: 'Sign in to view your saved items',
                    message:
                        'Saved venues, trails and events sync with the Vexda mobile app once you create an account.',
                    actionLabel: AppStrings.login,
                    onAction: () => Navigator.pushNamed(context, AppRouter.login),
                  ),
                  const SectionDivider(),
                  const SectionHeader(
                    title: 'Saved Venues',
                    subtitle: 'Venues you have bookmarked for tonight.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SavedSectionEmpty(
                    icon: Icons.storefront_outlined,
                    message: 'No saved venues yet. Explore search to find your next spot.',
                  ),
                  const SectionDivider(),
                  const SectionHeader(
                    title: 'Saved Trails',
                    subtitle: 'Tonight\'s Trails you want to join.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SavedSectionEmpty(
                    icon: Icons.route_outlined,
                    message: 'No saved trails yet. Discover curated routes on the map.',
                  ),
                  const SectionDivider(),
                  const SectionHeader(
                    title: 'Saved Events',
                    subtitle: 'Gigs, DJ sets and pop-ups on your radar.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SavedSectionEmpty(
                    icon: Icons.event_outlined,
                    message: 'No saved events yet. Browse live events from search.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: DrinkSpotButton(
                      label: 'Open Map',
                      variant: DrinkSpotButtonVariant.secondary,
                      onPressed: () => Navigator.pushNamed(context, AppRouter.map),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedSectionEmpty extends StatelessWidget {
  const _SavedSectionEmpty({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryPurple.withValues(alpha: 0.8), size: 28),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
