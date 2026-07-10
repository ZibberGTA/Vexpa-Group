import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../data/venue_contact_utils.dart';
import '../models/venue_details_view.dart';

/// Premium glass venue information panel for quick practical venue details.
class VenueDetailsInfoPanel extends StatelessWidget {
  const VenueDetailsInfoPanel({super.key, required this.venue});

  final VenueDetailsView venue;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPink.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PanelHeader(venue: venue),
                const SizedBox(height: AppSpacing.lg),
                _InfoSection(
                  title: 'Today',
                  children: [
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Opening hours today',
                      value: venue.todayHoursLabel,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _InfoSection(
                  title: 'Location',
                  children: [
                    if (venue.displayAddress.isNotEmpty)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: venue.displayAddress,
                      ),
                  ],
                ),
                if (venue.hasPhone || venue.hasWebsite) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InfoSection(
                    title: 'Contact',
                    children: [
                      if (venue.hasPhone)
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: venue.phone!,
                        ),
                      if (venue.hasPhone && venue.hasWebsite)
                        const SizedBox(height: AppSpacing.md),
                      if (venue.hasWebsite)
                        _InfoRow(
                          icon: Icons.language_rounded,
                          label: 'Website',
                          value: VenueContactUtils.displayWebsite(venue.website!),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _QuickActions(venue: venue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.venue});

  final VenueDetailsView venue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Venue information',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Quick details while you browse',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        _OpenBadge(isOpen: venue.isOpen),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryPink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryPink),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.primaryPink : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Text(
        isOpen ? 'Open now' : 'Closed',
        style: TextStyle(
          color: isOpen ? AppColors.white : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.venue});

  final VenueDetailsView venue;

  Future<void> _launchExternalUri(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${uri.scheme} link.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  void _showPlaceholder(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(
            color: AppColors.primaryPink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            DrinkSpotButton(
              label: 'Get directions',
              icon: Icons.directions_outlined,
              variant: DrinkSpotButtonVariant.secondary,
              compact: true,
              onPressed: () async {
                if (!venue.hasCoordinates) {
                  _showPlaceholder(context, 'Get directions');
                  return;
                }
                final uri = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=${venue.latitude},${venue.longitude}',
                );
                await _launchExternalUri(context, uri);
              },
            ),
            if (venue.hasPhone)
              DrinkSpotButton(
                label: 'Call venue',
                icon: Icons.phone_outlined,
                variant: DrinkSpotButtonVariant.primary,
                compact: true,
                onPressed: () {
                  final dialUri = VenueContactUtils.phoneDialUri(venue.phone);
                  final uri = dialUri == null ? null : Uri.tryParse(dialUri);
                  if (uri == null) {
                    _showPlaceholder(context, 'Call venue');
                    return;
                  }
                  _launchExternalUri(context, uri);
                },
              ),
            if (venue.hasWebsite)
              DrinkSpotButton(
                label: 'Visit website',
                icon: Icons.language_rounded,
                variant: DrinkSpotButtonVariant.primary,
                compact: true,
                onPressed: () {
                  final url = VenueContactUtils.normaliseWebsiteUrl(venue.website);
                  final uri = url == null ? null : Uri.tryParse(url);
                  if (uri == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Website link is not valid.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _launchExternalUri(context, uri);
                },
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
              label: 'Save',
              icon: Icons.bookmark_border_rounded,
              variant: DrinkSpotButtonVariant.ghost,
              compact: true,
              onPressed: () => _showPlaceholder(context, 'Save'),
            ),
            DrinkSpotButton(
              label: 'Share',
              icon: Icons.ios_share_rounded,
              variant: DrinkSpotButtonVariant.ghost,
              compact: true,
              onPressed: () => _showPlaceholder(context, 'Share'),
            ),
          ],
        ),
      ],
    );
  }
}
