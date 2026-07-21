import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/carousel_edge_fade.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_profile_completion.dart';
import '../../models/venue_trail_participation_presentation.dart';
import '../page/venue_dashboard_page_scaffold.dart';
import '../page/venue_dashboard_page_widgets.dart';
import '../venue_dashboard_controller.dart';
import 'venue_trails_presentation.dart';

/// Venue trails management workspace — discovery, participation and opportunities.
class VenueTrailsManagementPage extends StatelessWidget {
  const VenueTrailsManagementPage({
    super.key,
    this.discoveryTrails,
    this.participationTrails,
    this.opportunityTrails,
    this.profileCompletion,
    this.liveApplications,
    this.eligibleTrails,
    this.highlightedRequestId,
    this.busyParticipationRequestId,
    this.onDiscoveryJoin,
    this.onOpportunityJoin,
    this.onApplicationPrimaryAction,
  });

  final List<VenueTrailDiscoveryItem>? discoveryTrails;
  final List<VenueTrailParticipationItem>? participationTrails;
  final List<VenueTrailOpportunityItem>? opportunityTrails;
  final VenueProfileCompletion? profileCompletion;
  final List<VenueTrailParticipationApplicationPresentation>? liveApplications;
  final List<VenueTrailEligiblePresentation>? eligibleTrails;
  final String? highlightedRequestId;
  final String? busyParticipationRequestId;
  final Future<void> Function(String trailId)? onDiscoveryJoin;
  final Future<void> Function(String trailId)? onOpportunityJoin;
  final Future<void> Function(
    VenueTrailParticipationApplicationPresentation application,
  )?
  onApplicationPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final completion =
        profileCompletion ??
        controller?.homeData?.profileCompletion ??
        VenueProfileCompletion.mock;

    return VenueDashboardPageScaffold(
      tab: VenueDashboardTab.trails,
      mainContent: _VenueTrailsManagementContent(
        discoveryTrails:
            discoveryTrails ?? VenueTrailsPresentation.discoveryTrails,
        participationTrails:
            participationTrails ?? VenueTrailsPresentation.participationTrails,
        opportunityTrails:
            opportunityTrails ?? VenueTrailsPresentation.opportunityTrails,
        profileCompletion: completion,
        liveApplications: liveApplications,
        eligibleTrails: eligibleTrails,
        highlightedRequestId: highlightedRequestId,
        busyParticipationRequestId: busyParticipationRequestId,
        onDiscoveryJoin: onDiscoveryJoin,
        onOpportunityJoin: onOpportunityJoin,
        onApplicationPrimaryAction: onApplicationPrimaryAction,
      ),
    );
  }
}

class _VenueTrailsManagementContent extends StatelessWidget {
  const _VenueTrailsManagementContent({
    required this.discoveryTrails,
    required this.participationTrails,
    required this.opportunityTrails,
    required this.profileCompletion,
    this.liveApplications,
    this.eligibleTrails,
    this.highlightedRequestId,
    this.busyParticipationRequestId,
    this.onDiscoveryJoin,
    this.onOpportunityJoin,
    this.onApplicationPrimaryAction,
  });

  final List<VenueTrailDiscoveryItem> discoveryTrails;
  final List<VenueTrailParticipationItem> participationTrails;
  final List<VenueTrailOpportunityItem> opportunityTrails;
  final VenueProfileCompletion profileCompletion;
  final List<VenueTrailParticipationApplicationPresentation>? liveApplications;
  final List<VenueTrailEligiblePresentation>? eligibleTrails;
  final String? highlightedRequestId;
  final String? busyParticipationRequestId;
  final Future<void> Function(String trailId)? onDiscoveryJoin;
  final Future<void> Function(String trailId)? onOpportunityJoin;
  final Future<void> Function(
    VenueTrailParticipationApplicationPresentation application,
  )?
  onApplicationPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final showProfileCallout =
        VenueTrailsPresentation.shouldShowProfileReadinessCallout(
          profileCompletion,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenuePageSection(
          title: 'Trails Near You',
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: discoveryTrails.isEmpty
              ? const _TrailsDiscoveryEmptyState()
              : _TrailsNearYouCarousel(
                  trails: discoveryTrails,
                  onJoin: onDiscoveryJoin,
                  onViewDetails: onDiscoveryJoin,
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
        VenuePageSection(
          title: 'My Trail Participation',
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: participationTrails.isEmpty
              ? const _TrailParticipationEmptyState()
              : Column(
                  children: [
                    for (var i = 0; i < participationTrails.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _TrailParticipationRow(
                        item: participationTrails[i],
                        application:
                            liveApplications != null &&
                                i < liveApplications!.length
                            ? liveApplications![i]
                            : null,
                        highlighted:
                            liveApplications != null &&
                            i < liveApplications!.length &&
                            liveApplications![i].requestId ==
                                highlightedRequestId,
                        busy:
                            liveApplications != null &&
                            i < liveApplications!.length &&
                            liveApplications![i].requestId ==
                                busyParticipationRequestId,
                        onPrimaryAction: onApplicationPrimaryAction,
                      ),
                    ],
                  ],
                ),
        ),
        if (showProfileCallout) ...[
          const SizedBox(height: AppSpacing.xl),
          _TrailProfileReadinessCallout(
            onImproveProfile: () {
              VenueDashboardController.maybeOf(
                context,
              )?.selectTab(VenueDashboardTab.venueProfile);
            },
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        VenuePageSection(
          title: 'Trail Opportunities',
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: opportunityTrails.isEmpty
              ? const _TrailOpportunitiesEmptyState()
              : Column(
                  children: [
                    for (var i = 0; i < opportunityTrails.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _TrailOpportunityRow(
                        item: opportunityTrails[i],
                        onJoin: onOpportunityJoin,
                      ),
                    ],
                  ],
                ),
        ),
        // Trail Performance omitted: no reliable trail-specific metrics exist yet.
      ],
    );
  }
}

class _TrailsNearYouCarousel extends StatefulWidget {
  const _TrailsNearYouCarousel({
    required this.trails,
    this.onJoin,
    this.onViewDetails,
  });

  final List<VenueTrailDiscoveryItem> trails;
  final Future<void> Function(String trailId)? onJoin;
  final Future<void> Function(String trailId)? onViewDetails;

  @override
  State<_TrailsNearYouCarousel> createState() => _TrailsNearYouCarouselState();
}

class _TrailsNearYouCarouselState extends State<_TrailsNearYouCarousel> {
  late final ScrollController _controller;
  bool _hovered = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  double _scrollProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onScroll();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  bool get _isScrollPositionReady {
    if (!_controller.hasClients) return false;
    return _controller.position.hasContentDimensions;
  }

  void _onScroll() {
    if (!mounted || !_isScrollPositionReady) return;

    final position = _controller.position;
    final offset = position.pixels;
    final max = position.maxScrollExtent;
    final nextLeft = offset > 4;
    final nextRight = offset < max - 4;
    final progress = max <= 0 ? 0.0 : (offset / max).clamp(0.0, 1.0);

    if (nextLeft != _canScrollLeft ||
        nextRight != _canScrollRight ||
        progress != _scrollProgress) {
      setState(() {
        _canScrollLeft = nextLeft;
        _canScrollRight = nextRight;
        _scrollProgress = progress;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_isScrollPositionReady) return;

    final position = _controller.position;
    final target = (position.pixels + delta).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _TrailCarouselMetrics.resolve(
          context,
          constraints.maxWidth,
          widget.trails.length,
        );
        final needsScroll = metrics.needsScroll;
        final showArrows = Breakpoints.isDesktop(context) && needsScroll;

        final scroller = Listener(
          onPointerSignal: (signal) {
            if (!needsScroll) return;
            if (signal is PointerScrollEvent && signal.scrollDelta.dy != 0) {
              _scrollBy(signal.scrollDelta.dy);
            }
          },
          child: ListView.separated(
            key: const Key('venue-trails-near-you-list'),
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: needsScroll
                ? const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  )
                : const NeverScrollableScrollPhysics(),
            itemCount: widget.trails.length,
            separatorBuilder: (_, _) => SizedBox(width: metrics.spacing),
            itemBuilder: (context, index) {
              final trail = widget.trails[index];
              return SizedBox(
                width: metrics.cardWidth,
                height: metrics.cardHeight,
                child: _TrailDiscoveryCard(
                  key: ValueKey('trail-discovery-${trail.id}'),
                  item: trail,
                  onJoin: widget.onJoin,
                  onViewDetails: widget.onViewDetails,
                ),
              );
            },
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: SizedBox(
                height: metrics.cardHeight,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: needsScroll
                          ? CarouselEdgeFade(
                              showLeftEdge: _canScrollLeft,
                              showRightEdge: _canScrollRight,
                              surfaceTintColor: AppColors.surface,
                              child: scroller,
                            )
                          : scroller,
                    ),
                    if (showArrows) ...[
                      _TrailCarouselArrow(
                        visible: _hovered && _canScrollLeft,
                        alignment: Alignment.centerLeft,
                        icon: Icons.chevron_left_rounded,
                        onPressed: () => _scrollBy(-metrics.scrollStep),
                      ),
                      _TrailCarouselArrow(
                        visible: _canScrollRight,
                        alignment: Alignment.centerRight,
                        icon: Icons.chevron_right_rounded,
                        onPressed: () => _scrollBy(metrics.scrollStep),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (needsScroll && widget.trails.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              _TrailCarouselProgress(progress: _scrollProgress),
            ],
          ],
        );
      },
    );
  }
}

class _TrailCarouselMetrics {
  const _TrailCarouselMetrics({
    required this.cardWidth,
    required this.cardHeight,
    required this.spacing,
    required this.needsScroll,
    required this.scrollStep,
  });

  final double cardWidth;
  final double cardHeight;
  final double spacing;
  final bool needsScroll;
  final double scrollStep;

  static const _minCardWidth = 260.0;
  static const _maxCardWidth = 340.0;
  static const _cardHeight = 392.0;

  static _TrailCarouselMetrics resolve(
    BuildContext context,
    double viewportWidth,
    int itemCount,
  ) {
    const spacing = AppSpacing.lg;

    if (itemCount <= 0 || viewportWidth <= 0) {
      return const _TrailCarouselMetrics(
        cardWidth: 0,
        cardHeight: 0,
        spacing: spacing,
        needsScroll: false,
        scrollStep: 0,
      );
    }

    final cardsVisible = switch (Breakpoints.of(context)) {
      ScreenSize.desktop => 3.0,
      ScreenSize.tablet => 2.0,
      ScreenSize.mobile => 1.2,
    };

    final cardWidth =
        ((viewportWidth - (spacing * (cardsVisible - 1))) / cardsVisible).clamp(
          _minCardWidth,
          _maxCardWidth,
        );

    final totalWidth = (cardWidth * itemCount) + (spacing * (itemCount - 1));
    final needsScroll = totalWidth > viewportWidth + 1;

    return _TrailCarouselMetrics(
      cardWidth: cardWidth,
      cardHeight: _cardHeight,
      spacing: spacing,
      needsScroll: needsScroll,
      scrollStep: cardWidth + spacing,
    );
  }
}

class _TrailCarouselProgress extends StatelessWidget {
  const _TrailCarouselProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth * 0.42;
        final fillWidth = (trackWidth * progress.clamp(0.08, 1.0)).clamp(
          28.0,
          trackWidth,
        );

        return Center(
          child: SizedBox(
            width: trackWidth,
            height: 3,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const SizedBox(width: double.infinity, height: 3),
                ),
                AnimatedContainer(
                  duration: PremiumEffects.fast,
                  width: fillWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: AppColors.brandGradient,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrailCarouselArrow extends StatelessWidget {
  const _TrailCarouselArrow({
    required this.visible,
    required this.alignment,
    required this.icon,
    required this.onPressed,
  });

  final bool visible;
  final Alignment alignment;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0.35,
        duration: PremiumEffects.fast,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: AppColors.surfaceElevated.withValues(alpha: 0.94),
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: visible ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: AppColors.white, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailDiscoveryCard extends StatelessWidget {
  const _TrailDiscoveryCard({
    super.key,
    required this.item,
    this.onJoin,
    this.onViewDetails,
  });

  final VenueTrailDiscoveryItem item;
  final Future<void> Function(String trailId)? onJoin;
  final Future<void> Function(String trailId)? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final joinAction = VenueTrailActionResolver.discoveryJoinAction(
      item.venueState,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.38),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TrailDiscoveryArtwork(item: item),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg + 6,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  _TrailDiscoveryMetaGrid(item: item),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _TrailOutlinedAction(
                          label: 'View details',
                          enabled: onViewDetails != null,
                          onPressed: onViewDetails == null
                              ? null
                              : () => onViewDetails!(item.id),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child:
                            joinAction.useFilledStyle &&
                                joinAction.enabled &&
                                onJoin != null
                            ? _TrailFilledAction(
                                label: joinAction.label,
                                accentColor:
                                    item.venueState ==
                                        VenueTrailVenueState.requestAccess
                                    ? AppColors.primaryPurple
                                    : AppColors.primaryPink,
                                onPressed: () => onJoin!(item.id),
                              )
                            : _TrailOutlinedAction(
                                label: joinAction.label,
                                enabled: joinAction.enabled && onJoin != null,
                                onPressed: joinAction.enabled && onJoin != null
                                    ? () => onJoin!(item.id)
                                    : null,
                              ),
                      ),
                    ],
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

class _TrailDiscoveryArtwork extends StatelessWidget {
  const _TrailDiscoveryArtwork({required this.item});

  final VenueTrailDiscoveryItem item;

  static const _imageHeight = 148.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _imageHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusMd),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item.artworkGradient,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.42),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _TrailStatusBadge(label: item.status),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _TrailDistancePill(label: item.distance),
          ),
          Positioned(
            left: AppSpacing.md,
            bottom: -18,
            child: _TrailIconTile(
              icon: Icons.route_rounded,
              accentColor: AppColors.primaryPink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailDiscoveryMetaGrid extends StatelessWidget {
  const _TrailDiscoveryMetaGrid({required this.item});

  final VenueTrailDiscoveryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrailMetaLine(
          icon: Icons.storefront_outlined,
          label: item.venueCountLabel,
        ),
        const SizedBox(height: 4),
        _TrailMetaLine(icon: Icons.category_outlined, label: item.type),
        const SizedBox(height: 4),
        _TrailMetaLine(icon: Icons.event_outlined, label: item.startInfo),
      ],
    );
  }
}

class _TrailParticipationRow extends StatelessWidget {
  const _TrailParticipationRow({
    required this.item,
    this.application,
    this.highlighted = false,
    this.busy = false,
    this.onPrimaryAction,
  });

  final VenueTrailParticipationItem item;
  final VenueTrailParticipationApplicationPresentation? application;
  final bool highlighted;
  final bool busy;
  final Future<void> Function(
    VenueTrailParticipationApplicationPresentation application,
  )?
  onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final canAct = application != null && onPrimaryAction != null && !busy;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: highlighted
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.primaryPink.withValues(alpha: 0.55),
              ),
            )
          : null,
      child: _TrailInnerRow(
        child: Breakpoints.isMobile(context)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TrailParticipationBody(item: item),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _TrailRowAction(
                      label: busy ? 'Working…' : item.actionLabel,
                      enabled: canAct || (application == null),
                      onPressed: canAct
                          ? () => onPrimaryAction!(application!)
                          : application == null
                          ? () => showVenuePagePlaceholderAction(
                              context,
                              item.actionLabel,
                            )
                          : null,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _TrailParticipationBody(item: item)),
                  const SizedBox(width: AppSpacing.md),
                  _TrailRowAction(
                    label: busy ? 'Working…' : item.actionLabel,
                    enabled: canAct || (application == null),
                    onPressed: canAct
                        ? () => onPrimaryAction!(application!)
                        : application == null
                        ? () => showVenuePagePlaceholderAction(
                            context,
                            item.actionLabel,
                          )
                        : null,
                  ),
                ],
              ),
      ),
    );
  }
}

class _TrailParticipationBody extends StatelessWidget {
  const _TrailParticipationBody({required this.item});

  final VenueTrailParticipationItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TrailIconTile(
          icon: Icons.alt_route_rounded,
          accentColor: item.iconColor,
          size: 40,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TrailStatusBadge(label: item.status, compact: true),
                  _TrailMetaLine(
                    icon: Icons.format_list_numbered_rounded,
                    label: item.positionLabel,
                  ),
                  _TrailMetaLine(
                    icon: Icons.event_available_outlined,
                    label: item.availabilityLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrailOpportunityRow extends StatelessWidget {
  const _TrailOpportunityRow({required this.item, this.onJoin});

  final VenueTrailOpportunityItem item;
  final Future<void> Function(String trailId)? onJoin;

  @override
  Widget build(BuildContext context) {
    final action = VenueTrailActionResolver.opportunityAction(item.venueState);
    final statusBadge = VenueTrailActionResolver.eligibilityStatusBadge(
      item.venueState,
    );

    return _TrailInnerRow(
      child: Breakpoints.isMobile(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TrailOpportunityBody(item: item, statusBadge: statusBadge),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: _TrailRowAction(
                    label: action.label,
                    enabled: action.enabled,
                    onPressed: action.enabled && onJoin != null
                        ? () => onJoin!(item.id)
                        : action.enabled
                        ? () => showVenuePagePlaceholderAction(
                            context,
                            action.label,
                          )
                        : null,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _TrailOpportunityBody(
                    item: item,
                    statusBadge: statusBadge,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _TrailEligibilityBadge(
                      label: statusBadge,
                      state: item.venueState,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TrailRowAction(
                      label: action.label,
                      enabled: action.enabled,
                      onPressed: action.enabled
                          ? () => showVenuePagePlaceholderAction(
                              context,
                              action.label,
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _TrailOpportunityBody extends StatelessWidget {
  const _TrailOpportunityBody({required this.item, required this.statusBadge});

  final VenueTrailOpportunityItem item;
  final String statusBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrailIconTile(
          icon: item.icon,
          accentColor: AppColors.primaryPurple,
          size: 40,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final criterion in item.criteria.take(3))
                    _TrailMetaLine(
                      icon: Icons.check_circle_outline,
                      label: criterion,
                    ),
                ],
              ),
              if (Breakpoints.isMobile(context)) ...[
                const SizedBox(height: AppSpacing.sm),
                _TrailEligibilityBadge(
                  label: statusBadge,
                  state: item.venueState,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TrailInnerRow extends StatelessWidget {
  const _TrailInnerRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.34),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.14),
        ),
      ),
      child: child,
    );
  }
}

class _TrailProfileReadinessCallout extends StatelessWidget {
  const _TrailProfileReadinessCallout({required this.onImproveProfile});

  final VoidCallback onImproveProfile;

  @override
  Widget build(BuildContext context) {
    final stackOnNarrow = Breakpoints.isMobile(context);

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete your venue profile to improve your trail eligibility.',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Trails perform best when customers can see your photos, opening hours and location clearly.',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.95),
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ],
    );

    final action = _TrailRowAction(
      label: AppStrings.venueDashboardImproveProfile,
      onPressed: onImproveProfile,
    );

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: stackOnNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TrailIconTile(
                      icon: Icons.auto_fix_high_rounded,
                      accentColor: AppColors.primaryPink,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: copy),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerLeft, child: action),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _TrailIconTile(
                  icon: Icons.auto_fix_high_rounded,
                  accentColor: AppColors.primaryPink,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: copy),
                const SizedBox(width: AppSpacing.lg),
                action,
              ],
            ),
    );
  }
}

class _TrailsDiscoveryEmptyState extends StatelessWidget {
  const _TrailsDiscoveryEmptyState();

  @override
  Widget build(BuildContext context) {
    return _TrailEmptyPanel(
      icon: Icons.route_outlined,
      message:
          'When local trails are created, eligible venues will appear here.',
      actionLabel: 'Learn about Trails',
      onAction: () =>
          showVenuePagePlaceholderAction(context, 'Learn about Trails'),
    );
  }
}

class _TrailParticipationEmptyState extends StatelessWidget {
  const _TrailParticipationEmptyState();

  @override
  Widget build(BuildContext context) {
    return _TrailEmptyPanel(
      icon: Icons.alt_route_rounded,
      message:
          'Joined and approved trails will appear here once your venue is part of a route.',
    );
  }
}

class _TrailOpportunitiesEmptyState extends StatelessWidget {
  const _TrailOpportunitiesEmptyState();

  @override
  Widget build(BuildContext context) {
    return _TrailEmptyPanel(
      icon: Icons.add_road_outlined,
      message:
          'Trail opportunities matching your venue profile will appear here.',
    );
  }
}

class _TrailEmptyPanel extends StatelessWidget {
  const _TrailEmptyPanel({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.surfaceElevated.withValues(alpha: 0.34),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          _TrailIconTile(icon: icon, accentColor: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.md),
            _TrailRowAction(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class _TrailIconTile extends StatelessWidget {
  const _TrailIconTile({
    required this.icon,
    required this.accentColor,
    this.size = 36,
  });

  final IconData icon;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.88),
            AppColors.primaryPurple.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.48, color: AppColors.white),
    );
  }
}

class _TrailStatusBadge extends StatelessWidget {
  const _TrailStatusBadge({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (label.toLowerCase()) {
      'published' => AppColors.primaryPink,
      'scheduled' => AppColors.primaryPurple,
      'draft' => AppColors.trailGold,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 9.5 : 10,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}

class _TrailDistancePill extends StatelessWidget {
  const _TrailDistancePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.near_me_outlined,
            size: 11,
            color: AppColors.white.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailEligibilityBadge extends StatelessWidget {
  const _TrailEligibilityBadge({required this.label, required this.state});

  final String label;
  final VenueTrailVenueState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      VenueTrailVenueState.eligible => AppColors.primaryPink,
      VenueTrailVenueState.requestAccess => AppColors.trailGold,
      VenueTrailVenueState.requestPending => AppColors.primaryPurple,
      VenueTrailVenueState.notEligible => AppColors.textSecondary,
      VenueTrailVenueState.alreadyIncluded => AppColors.primaryPurple,
    };

    return Text(
      label,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TrailMetaLine extends StatelessWidget {
  const _TrailMetaLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrailRowAction extends StatelessWidget {
  const _TrailRowAction({
    required this.label,
    this.enabled = true,
    this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? AppColors.white : AppColors.textSecondary,
        side: BorderSide(
          color: enabled
              ? AppColors.primaryPurple.withValues(alpha: 0.34)
              : AppColors.border.withValues(alpha: 0.24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 38),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          if (enabled) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: enabled ? AppColors.white : AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrailOutlinedAction extends StatelessWidget {
  const _TrailOutlinedAction({
    required this.label,
    required this.enabled,
    this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? AppColors.white : AppColors.textSecondary,
        backgroundColor: AppColors.surface.withValues(alpha: 0.42),
        side: BorderSide(
          color: enabled
              ? AppColors.primaryPurple.withValues(alpha: 0.28)
              : AppColors.border.withValues(alpha: 0.24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        minimumSize: const Size(0, 40),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}

class _TrailFilledAction extends StatelessWidget {
  const _TrailFilledAction({
    required this.label,
    required this.accentColor,
    required this.onPressed,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor,
                Color.lerp(accentColor, AppColors.primaryPurple, 0.45)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
