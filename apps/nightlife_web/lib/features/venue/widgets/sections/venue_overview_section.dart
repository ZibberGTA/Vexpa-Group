import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/pill_tag.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../models/venue_details_view.dart';
import '../shared/venue_section_primitives.dart';

/// Venue overview, story, highlights and quick facts.
class VenueOverviewSection extends StatelessWidget {
  const VenueOverviewSection({super.key, required this.venue, this.anchorKey});

  final VenueDetailsView venue;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    return VenueSectionShell(
      anchorKey: anchorKey,
      title: 'Venue overview',
      subtitle: 'What makes ${venue.name} worth visiting tonight.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.xl),
            borderRadius: AppSpacing.radiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The story',
                  style: TextStyle(
                    color: AppColors.primaryPink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  venue.overviewDescription,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
          if (venue.highlights.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Venue highlights',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < venue.highlights.length; i++)
                  PillTag(label: venue.highlights[i], highlighted: i == 0),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final cards = [
                _FactCard(
                  icon: Icons.local_bar_rounded,
                  label: 'Type',
                  value: venue.displayCategory,
                ),
                _FactCard(
                  icon: Icons.schedule_rounded,
                  label: 'Tonight',
                  value: venue.isOpen ? 'Open now' : 'Closed',
                ),
                _FactCard(
                  icon: Icons.location_on_outlined,
                  label: 'Area',
                  value: venue.locationLabel,
                ),
              ];

              if (isWide) {
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: cards
                      .map((card) => SizedBox(width: (constraints.maxWidth - AppSpacing.md) / 2, child: card))
                      .toList(),
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    cards[i],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.radiusMd,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryPink, size: 20),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
