import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_empty_state.dart';
import '../../../shared/components/public_loading_state.dart';
import '../../../shared/components/section_header.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/nightlife_background.dart';
import '../../home/widgets/home_nav_bar.dart';
import '../data/trail_details_repository.dart';
import '../models/trail_details_view.dart';

/// Desktop trail details page — hero, route summary, stops, related trails.
class TrailDetailsPage extends StatefulWidget {
  const TrailDetailsPage({
    super.key,
    required this.trailId,
    this.repository,
  });

  final String trailId;
  final TrailDetailsRepository? repository;

  @override
  State<TrailDetailsPage> createState() => _TrailDetailsPageState();
}

class _TrailDetailsPageState extends State<TrailDetailsPage> {
  late final TrailDetailsRepository _repository;
  late final Future<TrailDetailsView?> _trailFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TrailDetailsRepository();
    _trailFuture = _repository.loadTrail(widget.trailId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const HomeNavBar(),
          Expanded(
            child: FutureBuilder<TrailDetailsView?>(
              future: _trailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const PublicLoadingState(message: 'Loading trail…');
                }

                final trail = snapshot.data;
                if (trail == null) {
                  return PublicEmptyState(
                    icon: Icons.route_outlined,
                    title: 'Trail not found',
                    message: 'This trail may have ended or is no longer available.',
                    actionLabel: 'Explore map',
                    onAction: () => Navigator.pushNamed(context, AppRouter.map),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TrailHero(trail: trail),
                      ContentContainer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 900;
                              return Flex(
                                direction: isWide ? Axis.horizontal : Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SectionHeader(
                                          title: 'Route summary',
                                          subtitle: trail.description.isNotEmpty
                                              ? trail.description
                                              : 'A curated Tonight\'s Trail across ${trail.stops.length} venues.',
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        Wrap(
                                          spacing: AppSpacing.md,
                                          runSpacing: AppSpacing.md,
                                          children: [
                                            _MetricChip(
                                              icon: Icons.timer_outlined,
                                              label:
                                                  '~${trail.estimatedWalkingMinutes} min walking',
                                            ),
                                            _MetricChip(
                                              icon: Icons.storefront_outlined,
                                              label: '${trail.stops.length} venues',
                                            ),
                                            if (trail.area.isNotEmpty)
                                              _MetricChip(
                                                icon: Icons.location_on_outlined,
                                                label: trail.area,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.xxl),
                                        const SectionHeader(
                                          title: 'Venue stops',
                                          subtitle: 'Follow the route in order for the best experience.',
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        ...trail.stops.map(
                                          (stop) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.md,
                                            ),
                                            child: _TrailStopCard(stop: stop),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? AppSpacing.xl : 0,
                                    height: isWide ? 0 : AppSpacing.xl,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: GlassContainer(
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Interactive route',
                                            style: TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          const Text(
                                            'Live route map integration coming soon. Download the app to join this trail tonight.',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          Container(
                                            height: 280,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                AppSpacing.radiusMd,
                                              ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.trailGold.withValues(alpha: 0.15),
                                                  AppColors.deepPurple.withValues(alpha: 0.5),
                                                ],
                                              ),
                                              border: Border.all(color: AppColors.glassBorder),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.route_outlined,
                                                color: AppColors.trailGold,
                                                size: 48,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          DrinkSpotButton(
                                            label: AppStrings.downloadApp,
                                            onPressed: () => Navigator.pushNamed(
                                              context,
                                              AppRouter.download,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      _RelatedTrailsSection(
                        trailId: trail.id,
                        repository: _repository,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailHero extends StatelessWidget {
  const _TrailHero({required this.trail});

  final TrailDetailsView trail;

  @override
  Widget build(BuildContext context) {
    final hasBanner = trail.bannerImageUrl.trim().isNotEmpty;

    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasBanner)
            Image.network(
              trail.bannerImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const AtmosphericPageBackground(),
            )
          else
            const AtmosphericPageBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.trailGold.withValues(alpha: 0.08),
                  AppColors.background.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
          ContentContainer(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TONIGHT\'S TRAIL',
                      style: TextStyle(
                        color: AppColors.trailGold.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      trail.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.trailGold),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailStopCard extends StatelessWidget {
  const _TrailStopCard({required this.stop});

  final TrailStopView stop;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Center(
              child: Text(
                '${stop.order}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.venueName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (stop.address.isNotEmpty)
                  Text(
                    stop.address,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                if (stop.discountLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      stop.discountLabel,
                      style: TextStyle(
                        color: AppColors.trailGold.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (stop.venueId.isNotEmpty)
            DrinkSpotButton(
              label: 'View',
              compact: true,
              variant: DrinkSpotButtonVariant.ghost,
              onPressed: () => Navigator.pushNamed(
                context,
                AppRouter.venueDetails(stop.venueId),
              ),
            ),
        ],
      ),
    );
  }
}

class _RelatedTrailsSection extends StatelessWidget {
  const _RelatedTrailsSection({
    required this.trailId,
    required this.repository,
  });

  final String trailId;
  final TrailDetailsRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrailDetailsView>>(
      future: repository.loadRelatedTrails(trailId),
      builder: (context, snapshot) {
        final trails = snapshot.data ?? const [];
        if (trails.isEmpty) return const SizedBox.shrink();

        return ContentContainer(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Related trails',
                  subtitle: 'More Tonight\'s Trails to explore.',
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: trails
                      .map(
                        (trail) => GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.trailDetails(trail.id),
                          ),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: SizedBox(
                              width: 260,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trail.name,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${trail.stops.length} venues · ${trail.area}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
