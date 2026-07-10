import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../models/venue_details_view.dart';
import '../../models/venue_opening_hours_entry.dart';
import '../shared/venue_section_primitives.dart';

/// Extended venue information for the main content column.
class VenueInformationSection extends StatelessWidget {
  const VenueInformationSection({super.key, required this.venue, this.anchorKey});

  final VenueDetailsView venue;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    return VenueSectionShell(
      anchorKey: anchorKey,
      title: 'Information',
      subtitle: 'Everything you need before you head out.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassContainer(
            borderRadius: AppSpacing.radiusLg,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _InfoHeading(label: 'Opening hours'),
                const SizedBox(height: AppSpacing.sm),
                if (!venue.hasOpeningHours)
                  const Text(
                    'Opening hours are not available for this venue yet.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < venue.openingHours.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == venue.openingHours.length - 1 ? 0 : AppSpacing.xs,
                          ),
                          child: _HoursLine(entry: venue.openingHours[i]),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassContainer(
            borderRadius: AppSpacing.radiusLg,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _InfoHeading(label: 'Contact & access'),
                const SizedBox(height: AppSpacing.sm),
                _DetailLine(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: venue.displayAddress,
                ),
                if (venue.hasPhone) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailLine(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: venue.phone!,
                  ),
                ],
                if (venue.hasWebsite) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailLine(
                    icon: Icons.language_rounded,
                    label: 'Website',
                    value: venue.website!,
                  ),
                ],
                if (venue.highlights.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _InfoHeading(label: 'Facilities & highlights'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    venue.highlights.join(' • '),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const _InfoHeading(label: 'Policies'),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Venue policies will appear here when provided by the venue.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoHeading extends StatelessWidget {
  const _InfoHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryPink,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _HoursLine extends StatelessWidget {
  const _HoursLine({required this.entry});

  final VenueOpeningHoursEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            entry.dayLabel,
            style: TextStyle(
              color: entry.isToday ? AppColors.white : AppColors.textSecondary,
              fontWeight: entry.isToday ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          entry.hoursLabel,
          style: TextStyle(
            color: entry.isToday ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
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
        Icon(icon, size: 16, color: AppColors.primaryPink),
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
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
