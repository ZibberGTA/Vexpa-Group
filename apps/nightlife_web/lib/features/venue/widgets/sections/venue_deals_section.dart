import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../data/models/deal_model.dart';
import '../../data/public_venue_content_filters.dart';
import '../../data/venue_deals_repository.dart';
import '../shared/upcoming_venue_card_style.dart';
import '../shared/venue_section_primitives.dart';

/// Active and upcoming deals for a venue.
class VenueDealsSection extends StatelessWidget {
  const VenueDealsSection({
    super.key,
    required this.venueId,
    this.repository,
    this.anchorKey,
    this.now,
  });

  final String venueId;
  final VenueDealsRepository? repository;
  final Key? anchorKey;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? VenueDealsRepository();
    final clock = now ?? DateTime.now();

    return VenueSectionShell(
      anchorKey: anchorKey,
      title: 'Deals',
      subtitle: 'Current offers and upcoming promotions.',
      child: StreamBuilder<List<DealModel>>(
        stream: repo.watchDeals(venueId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const VenueEmptyState(
              icon: Icons.local_offer_outlined,
              title: 'Deals unavailable',
              message: 'We could not load deals for this venue right now.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const VenueSectionLoading(lines: 3);
          }

          final deals = snapshot.data ?? [];
          final current = deals
              .where((deal) => isPublicCurrentDeal(deal, now: clock))
              .toList();
          final upcoming = deals
              .where((deal) => isPublicUpcomingDeal(deal, now: clock))
              .toList();

          if (current.isEmpty && upcoming.isEmpty) {
            return const VenueEmptyState(
              icon: Icons.local_offer_outlined,
              title: 'No active deals',
              message:
                  'Current deals will appear here. Expired and paused deals are hidden automatically.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (current.isNotEmpty) ...[
                const _Subheading(label: 'Current Deals'),
                const SizedBox(height: AppSpacing.sm),
                for (final deal in current)
                  _CurrentDealCard(
                    deal: deal,
                    featured: deal.featured,
                  ),
              ],
              if (upcoming.isNotEmpty) ...[
                SizedBox(height: current.isNotEmpty ? AppSpacing.lg : 0),
                const _Subheading(label: 'Upcoming Deals'),
                const SizedBox(height: AppSpacing.sm),
                for (final deal in upcoming)
                  _UpcomingDealCard(
                    deal: deal,
                    startLabel: formatUpcomingStartLabel(
                      deal.startDateTime ?? clock,
                      now: clock,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryPink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _CurrentDealCard extends StatefulWidget {
  const _CurrentDealCard({required this.deal, this.featured = false});

  final DealModel deal;
  final bool featured;

  @override
  State<_CurrentDealCard> createState() => _CurrentDealCardState();
}

class _CurrentDealCardState extends State<_CurrentDealCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: widget.featured ? AppColors.brandGradient : null,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.featured ? 1.6 : 0),
            child: GlassContainer(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer_rounded,
                        color: AppColors.primaryPink,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          deal.title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (widget.featured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Featured',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (deal.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      deal.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    [
                      if (deal.startTime.isNotEmpty || deal.endTime.isNotEmpty)
                        '${deal.startTime}${deal.endTime.isNotEmpty ? ' – ${deal.endTime}' : ''}',
                      deal.expiryLabel,
                    ].where((part) => part.trim().isNotEmpty).join(' • '),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DrinkSpotButton(
                    label: 'View Details',
                    compact: true,
                    variant: DrinkSpotButtonVariant.secondary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Deal details coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingDealCard extends StatefulWidget {
  const _UpcomingDealCard({
    required this.deal,
    required this.startLabel,
  });

  final DealModel deal;
  final String startLabel;

  @override
  State<_UpcomingDealCard> createState() => _UpcomingDealCardState();
}

class _UpcomingDealCardState extends State<_UpcomingDealCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: upcomingVenueCardDecoration(hovered: _hovered),
          child: Padding(
            padding: const EdgeInsets.all(1.4),
            child: GlassContainer(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: AppColors.trailGold.withValues(alpha: 0.95),
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          deal.title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const UpcomingVenueBadge(),
                    ],
                  ),
                  if (deal.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      deal.description,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.95),
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.startLabel,
                    style: TextStyle(
                      color: AppColors.trailGold.withValues(alpha: 0.95),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DrinkSpotButton(
                    label: 'View Details',
                    compact: true,
                    variant: DrinkSpotButtonVariant.ghost,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Deal details coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
