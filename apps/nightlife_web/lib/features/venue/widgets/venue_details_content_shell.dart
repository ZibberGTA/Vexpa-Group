import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/venue_details_view.dart';
import 'venue_details_hero.dart';
import 'venue_details_info_panel.dart';
import 'venue_details_main_content.dart';

/// Main content shell for the venue details page.
class VenueDetailsContentShell extends StatelessWidget {
  const VenueDetailsContentShell({super.key, required this.venue});

  final VenueDetailsView venue;

  void _backToSearch(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRouter.search);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalInset = Breakpoints.horizontalPadding(context);
    final isDesktop = Breakpoints.isDesktop(context);

    if (isDesktop) {
      final maxPanelHeight = MediaQuery.sizeOf(context).height -
          Breakpoints.reservedNavHeight(context) -
          AppSpacing.xxxl;

      return Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          AppSpacing.lg,
          horizontalInset,
          AppSpacing.xxxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BackToSearchLink(onPressed: () => _backToSearch(context)),
                        const SizedBox(height: AppSpacing.sm),
                        VenueDetailsHero(
                          venue: venue,
                          onBackToSearch: () => _backToSearch(context),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        VenueDetailsMainContent(venue: venue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(
                  width: 360,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxPanelHeight.clamp(320, double.infinity),
                      ),
                      child: SingleChildScrollView(
                        child: VenueDetailsInfoPanel(venue: venue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        AppSpacing.lg,
        horizontalInset,
        AppSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BackToSearchLink(onPressed: () => _backToSearch(context)),
              const SizedBox(height: AppSpacing.sm),
              VenueDetailsHero(
                venue: venue,
                onBackToSearch: () => _backToSearch(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              VenueDetailsInfoPanel(venue: venue),
              const SizedBox(height: AppSpacing.xl),
              VenueDetailsMainContent(venue: venue),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackToSearchLink extends StatelessWidget {
  const _BackToSearchLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
        label: const Text(
          'Back to search',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
