import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/home_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../core/widgets/premium_scaffold.dart';
import '../../map/screens/venue_map_screen.dart';
import '../../startup/services/startup_cache.dart';
import '../models/trail_model.dart';
import '../services/trail_service.dart';

enum _TrailSortOption { closest, highestRated }

extension _TrailSortOptionX on _TrailSortOption {
  String get label {
    switch (this) {
      case _TrailSortOption.closest:
        return 'Closest';
      case _TrailSortOption.highestRated:
        return 'Top rated';
    }
  }
}

class TonightsTrailScreen extends StatefulWidget {
  const TonightsTrailScreen({super.key});

  @override
  State<TonightsTrailScreen> createState() => _TonightsTrailScreenState();
}

class _TonightsTrailScreenState extends State<TonightsTrailScreen> {
  _TrailSortOption _sortOption = _TrailSortOption.closest;
  String? _joiningTrailId;

  Future<void> _joinTrail(DrinkSpotTrailModel trail) async {
    if (_joiningTrailId != null) return;
    setState(() => _joiningTrailId = trail.id);

    try {
      await TrailService.joinTrail(trail.id, trail: trail);
      if (!mounted) return;
      setState(() => _joiningTrailId = null);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _TrailExperienceScreen(trail: trail)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _joiningTrailId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not join trail: $error')));
    }
  }

  List<_TrailDiscoveryItem> _itemsFor(List<DrinkSpotTrailModel> trails) {
    final items = trails
        .map(
          (trail) => _TrailDiscoveryItem(
            trail: trail,
            distanceMeters: _distanceToTrailMeters(trail),
          ),
        )
        .toList();

    items.sort((a, b) {
      final typeComparison = a.trail.trailType.index.compareTo(
        b.trail.trailType.index,
      );
      if (typeComparison != 0) return typeComparison;

      switch (_sortOption) {
        case _TrailSortOption.closest:
          final aDistance = a.distanceMeters;
          final bDistance = b.distanceMeters;
          if (aDistance == null && bDistance == null) {
            return b.trail.averageRating.compareTo(a.trail.averageRating);
          }
          if (aDistance == null) return 1;
          if (bDistance == null) return -1;
          return aDistance.compareTo(bDistance);
        case _TrailSortOption.highestRated:
          return b.trail.averageRating.compareTo(a.trail.averageRating);
      }
    });

    return items;
  }

  double? _distanceToTrailMeters(DrinkSpotTrailModel trail) {
    final startupData = StartupCache.data;
    if (startupData?.hasUserLocation != true) return null;

    final userLat = startupData!.userLatitude!;
    final userLng = startupData.userLongitude!;
    final venuesById = {
      for (final venue in startupData.venues) venue.id: venue,
      for (final venue in startupData.nearbyVenues) venue.id: venue,
    };

    double? closestMeters;
    for (final stop in trail.stops) {
      final location = venuesById[stop.venueId]?.location;
      if (location == null) continue;
      final meters = Geolocator.distanceBetween(
        userLat,
        userLng,
        location.latitude,
        location.longitude,
      );
      if (closestMeters == null || meters < closestMeters) {
        closestMeters = meters;
      }
    }

    return closestMeters;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      body: StreamBuilder<List<DrinkSpotTrailModel>>(
        stream: TrailService.watchVisibleTrails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final trails = snapshot.data ?? const <DrinkSpotTrailModel>[];
          final items = _itemsFor(trails);
          _TrailDiscoveryItem? featuredItem;
          for (final item in items) {
            if (item.trail.trailType == TrailType.curated) {
              featuredItem = item;
              break;
            }
          }
          final remainingItems = featuredItem == null
              ? items
              : items
                    .where((item) => item.trail.id != featuredItem!.trail.id)
                    .toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _TrailDiscoveryHeader(
                    sortOption: _sortOption,
                    onSortChanged: (value) {
                      if (value == null) return;
                      setState(() => _sortOption = value);
                    },
                  ),
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoTrailsAvailable(
                    onExploreMap: () => Navigator.of(context).maybePop(),
                  ),
                )
              else ...[
                if (featuredItem != null) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    sliver: const SliverToBoxAdapter(
                      child: _FeaturedSectionLabel(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    sliver: SliverToBoxAdapter(
                      child: _TrailDiscoveryCard(
                        item: featuredItem,
                        featured: true,
                        joining: _joiningTrailId == featuredItem.trail.id,
                        onJoin: () => _joinTrail(featuredItem!.trail),
                      ),
                    ),
                  ),
                ],
                if (remainingItems.isNotEmpty) ...[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      featuredItem == null ? 2 : 0,
                      16,
                      8,
                    ),
                    sliver: const SliverToBoxAdapter(
                      child: _SectionTitle('More trails near you'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList.builder(
                      itemCount: remainingItems.length * 2 - 1,
                      itemBuilder: (context, index) {
                        if (index.isOdd) return const SizedBox(height: 10);
                        final item = remainingItems[index ~/ 2];
                        return _TrailDiscoveryCard(
                          item: item,
                          joining: _joiningTrailId == item.trail.id,
                          onJoin: () => _joinTrail(item.trail),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TrailDiscoveryItem {
  const _TrailDiscoveryItem({
    required this.trail,
    required this.distanceMeters,
  });

  final DrinkSpotTrailModel trail;
  final double? distanceMeters;
}

class _TrailDiscoveryHeader extends StatelessWidget {
  const _TrailDiscoveryHeader({
    required this.sortOption,
    required this.onSortChanged,
  });

  final _TrailSortOption sortOption;
  final ValueChanged<_TrailSortOption?> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              PopupMenuButton<_TrailSortOption>(
                tooltip: 'Sort trails',
                color: const Color(0xFF1E2030),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.white.withOpacity(0.10)),
                ),
                offset: const Offset(0, 46),
                onSelected: onSortChanged,
                itemBuilder: (context) => _TrailSortOption.values
                    .map(
                      (option) => PopupMenuItem<_TrailSortOption>(
                        value: option,
                        child: Row(
                          children: [
                            Icon(
                              option == sortOption
                                  ? Icons.check_rounded
                                  : Icons.sort_rounded,
                              color: option == sortOption
                                  ? AppColors.primaryPink
                                  : Colors.white54,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(option.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2030).withOpacity(0.76),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Sort',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: "Tonight's ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  TextSpan(
                    text: 'Trails',
                    style: TextStyle(
                      color: AppColors.primaryPink,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Curated routes through the best spots tonight.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E2030).withOpacity(0.76),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _FeaturedSectionLabel extends StatelessWidget {
  const _FeaturedSectionLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '⭐ Featured by DrinkSpot',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPink.withOpacity(0.45),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TrailDiscoveryCard extends StatelessWidget {
  const _TrailDiscoveryCard({
    required this.item,
    required this.joining,
    required this.onJoin,
    this.featured = false,
  });

  final _TrailDiscoveryItem item;
  final bool joining;
  final VoidCallback onJoin;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final trail = item.trail;
    final venueCount = trail.venueCount > 0
        ? trail.venueCount
        : trail.stops.length;
    final metricChips = <Widget>[
      if (item.distanceMeters != null)
        _TrailMetricChip(
          icon: Icons.near_me_rounded,
          label: DistanceFormatter.formatMeters(item.distanceMeters!),
        ),
      if (trail.estimatedDuration.inMinutes > 0)
        _TrailMetricChip(
          icon: Icons.schedule_rounded,
          label: _formatTrailDuration(trail.estimatedDuration),
        ),
      if (venueCount > 0)
        _TrailMetricChip(
          icon: Icons.storefront_rounded,
          label: '$venueCount venue${venueCount == 1 ? '' : 's'}',
        ),
    ];

    const outerRadius = 22.0;
    const borderWidth = 1.4;
    const innerRadius = outerRadius - borderWidth;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: featured ? 112 : 104),
      child: Container(
        padding: const EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerRadius),
          gradient: featured
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD166),
                    Color(0xFFFF2D95),
                    Color(0xFF9D28FF),
                    Color(0xFF5B1D9A),
                  ],
                  stops: [0.0, 0.34, 0.72, 1.0],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPink.withOpacity(0.34),
                    AppColors.primaryPurple.withOpacity(0.42),
                    const Color(0xFF5B1D9A).withOpacity(0.32),
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.11),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Container(
            color: const Color(0xFF1E2030).withOpacity(0.68),
            child: Stack(
              children: [
                Positioned.fill(child: _TrailCardBackground(trail: trail)),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.84),
                          Colors.black.withOpacity(0.50),
                          Colors.black.withOpacity(0.12),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.76),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.62,
                        child: Text(
                          trail.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: featured ? 17 : 16,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      _TrailRatingRow(rating: trail.averageRating),
                      if (metricChips.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Wrap(spacing: 4, runSpacing: 3, children: metricChips),
                      ],
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 3,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _TrailMetricChip(
                                  icon: Icons.event_available_rounded,
                                  label: _formatAvailabilityWindow(trail),
                                ),
                                const _TonightChip(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          _JoinTrailButton(joining: joining, onJoin: onJoin),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailRatingRow extends StatelessWidget {
  const _TrailRatingRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final label = rating > 0 ? rating.toStringAsFixed(1) : 'Not rated yet';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          5,
          (index) => Icon(
            rating >= index + 1
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: 13,
            color: AppColors.primaryPink,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TrailCardBackground extends StatelessWidget {
  const _TrailCardBackground({required this.trail});

  final DrinkSpotTrailModel trail;

  @override
  Widget build(BuildContext context) {
    final imageUrl = trail.bannerImageUrl.trim();

    if (imageUrl.isEmpty) return const _TrailHeroPlaceholder();

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      cacheWidth: 1000,
      errorBuilder: (_, _, _) => const _TrailHeroPlaceholder(),
    );
  }
}

/// Hero-only banner with subtle brightness/saturation lift for the active trail screen.
class _TrailHeroBannerBackground extends StatelessWidget {
  const _TrailHeroBannerBackground({required this.trail});

  final DrinkSpotTrailModel trail;

  static const List<double> _saturationMatrix = <double>[
    1.063,
    -0.057,
    -0.006,
    0,
    0,
    -0.023,
    1.022,
    -0.006,
    0,
    0,
    -0.023,
    -0.057,
    1.073,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _brightnessMatrix = <double>[
    1.07,
    0,
    0,
    0,
    6,
    0,
    1.07,
    0,
    0,
    6,
    0,
    0,
    1.07,
    0,
    6,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    final imageUrl = trail.bannerImageUrl.trim();

    if (imageUrl.isEmpty) return const _TrailHeroPlaceholder();

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_saturationMatrix),
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_brightnessMatrix),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 1000,
          errorBuilder: (_, _, _) => const _TrailHeroPlaceholder(),
        ),
      ),
    );
  }
}

class _TrailHeroPlaceholder extends StatelessWidget {
  const _TrailHeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleDark.withOpacity(0.98),
            AppColors.purple.withOpacity(0.74),
            const Color(0xFF111218),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.local_bar_rounded, color: Colors.white70, size: 42),
      ),
    );
  }
}

class _TrailMetricChip extends StatelessWidget {
  const _TrailMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryPurple),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TonightChip extends StatelessWidget {
  const _TonightChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.28)),
      ),
      child: const Text(
        'Tonight',
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _JoinTrailButton extends StatelessWidget {
  const _JoinTrailButton({required this.joining, required this.onJoin});

  final bool joining;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: joining ? null : onJoin,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryPurple.withOpacity(0.84),
                AppColors.primaryPink.withOpacity(0.84),
              ],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (joining)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.route_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(
                joining ? 'Joining' : 'Join Trail',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!joining) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoTrailsAvailable extends StatelessWidget {
  const _NoTrailsAvailable({required this.onExploreMap});

  final VoidCallback onExploreMap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2030).withOpacity(0.70),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primaryPurple.withOpacity(0.28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: AppColors.primaryPurple,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No trails nearby right now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later — new trails appear every day!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onExploreMap,
                icon: const Icon(Icons.map_rounded),
                label: const Text('Explore Map'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailExperienceScreen extends StatelessWidget {
  const _TrailExperienceScreen({required this.trail});

  final DrinkSpotTrailModel trail;

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(title: Text(trail.name)),
      body: StreamBuilder<TrailProgressModel?>(
        stream: TrailService.watchMyTrailProgress(trailId: trail.id),
        builder: (context, progressSnapshot) {
          final rawProgress = progressSnapshot.data;
          final progress = rawProgress != null && rawProgress.belongsTo(trail)
              ? rawProgress
              : null;
          final started = progress?.started == true;
          final trailCompleted = progress?.completed == true;
          final currentStop = (progress?.currentStop ?? 0).clamp(
            0,
            trail.stops.isEmpty ? 0 : trail.stops.length - 1,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _TrailHero(trail: trail),
              const SizedBox(height: 16),
              if (!started)
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await TrailService.startTrail(trail);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trail started')),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Trail'),
                  ),
                ),
              if (trailCompleted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.green.withOpacity(0.45)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: Colors.greenAccent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Trail completed. Nice one!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              ...trail.stops.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                final status =
                    progress?.stateForStop(
                      stop: stop,
                      index: index,
                      trailCompleted: trailCompleted,
                    ) ??
                    (index == 0
                        ? TrailStopProgressState.current
                        : TrailStopProgressState.upcoming);
                final checkedIn =
                    status == TrailStopProgressState.checkedIn ||
                    status == TrailStopProgressState.completed;
                final active =
                    started && !trailCompleted && index == currentStop;
                final canCheckIn =
                    started &&
                    !trailCompleted &&
                    index >= currentStop &&
                    !status.isTerminal;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TrailStopCard(
                    stop: stop,
                    active: active,
                    checkedIn: checkedIn,
                    status: status,
                    onArrived: !canCheckIn
                        ? null
                        : () async {
                            final validation =
                                await TrailService.validateStopCheckIn(
                                  stop: stop,
                                );
                            if (!context.mounted) return;

                            if (!validation.allowed) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    validation.message ??
                                        'You are not close enough to check in.',
                                  ),
                                ),
                              );
                              return;
                            }

                            await TrailService.checkInAtStop(
                              trail: trail,
                              stop: stop,
                              stopIndex: index,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Checked in at ${stop.venueName}',
                                ),
                              ),
                            );
                          },
                    onNext: !active || !checkedIn
                        ? null
                        : () async {
                            final nextStopIndex =
                                await TrailService.continueTrail(
                                  trail: trail,
                                  stop: stop,
                                  stopIndex: index,
                                );
                            if (!context.mounted) return;
                            if (nextStopIndex == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Trail completed'),
                                ),
                              );
                            }
                          },
                    onDirections: !started || trailCompleted
                        ? null
                        : () async {
                            await TrailService.logTrailDirectionsRequested(
                              trailId: trail.id,
                              stop: stop,
                            );
                            if (!context.mounted) return;
                            VenueMapScreen.pendingRoute.value =
                                VenueMapPendingRoute(
                                  venueId: stop.venueId,
                                  trail: trail,
                                  trailStop: stop,
                                  trailStopIndex: index,
                                );
                            HomeNavigationService.goHome(context);
                          },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _TrailHero extends StatelessWidget {
  const _TrailHero({required this.trail});

  final DrinkSpotTrailModel trail;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.36)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.11),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Positioned.fill(child: _TrailHeroBannerBackground(trail: trail)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.18),
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.32),
                    ],
                    stops: const [0.0, 0.42, 0.68, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 30)),
                  const SizedBox(height: 10),
                  Text(
                    trail.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trail.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroPill('${trail.stops.length} stops'),
                      _HeroPill(
                        '${time.format(trail.startTime)} - ${time.format(trail.endTime)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailStopCard extends StatelessWidget {
  const _TrailStopCard({
    required this.stop,
    required this.active,
    required this.checkedIn,
    required this.status,
    required this.onArrived,
    required this.onNext,
    required this.onDirections,
  });

  final TrailStopModel stop;
  final bool active;
  final bool checkedIn;
  final TrailStopProgressState status;
  final VoidCallback? onArrived;
  final VoidCallback? onNext;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm');
    final statusColor = _colorForStopStatus(status, active: active);
    final statusIcon = _iconForStopStatus(status, active: active);
    final showActions = active || onArrived != null;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withOpacity(0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(active ? 0.65 : 0.38),
        ),
      ),
      child: Stack(
        children: [
          if (stop.bannerImageUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                stop.bannerImageUrl,
                fit: BoxFit.cover,
                cacheWidth: 900,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.22),
                    Colors.black.withOpacity(0.86),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor,
                      child: statusIcon != null
                          ? Icon(statusIcon, color: Colors.white)
                          : Text(
                              '${stop.order}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.venueName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (stop.address.isNotEmpty)
                            Text(
                              stop.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroPill('Arrive ${time.format(stop.arriveAt)}'),
                    _HeroPill('Leave ${time.format(stop.leaveAt)}'),
                    if (stop.discountLabel.trim().isNotEmpty)
                      _HeroPill(stop.discountLabel.trim()),
                    _HeroPill(status.label),
                  ],
                ),
                if (showActions) ...[
                  const SizedBox(height: 14),
                  if (active) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onDirections,
                        icon: const Icon(Icons.directions_walk_rounded),
                        label: Text('Directions to ${stop.venueName}'),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onArrived,
                          icon: Icon(
                            checkedIn
                                ? Icons.check_circle_rounded
                                : Icons.location_on_rounded,
                          ),
                          label: Text(checkedIn ? 'Checked-in' : "I'm here"),
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: onNext,
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorForStopStatus(
  TrailStopProgressState status, {
  required bool active,
}) {
  if (active && status == TrailStopProgressState.current) {
    return AppColors.primaryPurple;
  }
  switch (status) {
    case TrailStopProgressState.checkedIn:
    case TrailStopProgressState.completed:
      return Colors.green;
    case TrailStopProgressState.current:
      return AppColors.primaryPurple;
    case TrailStopProgressState.skipped:
      return Colors.orange;
    case TrailStopProgressState.missed:
      return Colors.redAccent;
    case TrailStopProgressState.upcoming:
      return Colors.grey;
  }
}

IconData? _iconForStopStatus(
  TrailStopProgressState status, {
  required bool active,
}) {
  switch (status) {
    case TrailStopProgressState.checkedIn:
    case TrailStopProgressState.completed:
      return Icons.check_rounded;
    case TrailStopProgressState.current:
      return active ? Icons.navigation_rounded : null;
    case TrailStopProgressState.skipped:
      return Icons.skip_next_rounded;
    case TrailStopProgressState.missed:
      return Icons.close_rounded;
    case TrailStopProgressState.upcoming:
      return null;
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatTrailDuration(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes <= 0) return 'TBC';
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}m';
}

String _formatAvailabilityWindow(DrinkSpotTrailModel trail) {
  final time = DateFormat('HH:mm');
  return '${time.format(trail.availabilityStart)} - ${time.format(trail.availabilityEnd)}';
}
