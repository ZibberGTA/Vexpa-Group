import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../models/discover_models.dart';
import '../utils/discover_carousel_scroll.dart';
import 'discover_results_header.dart';
import 'discover_venue_card.dart';

class DiscoverResultsPanel extends StatefulWidget {
  const DiscoverResultsPanel({
    super.key,
    required this.filter,
    required this.loadState,
    required this.expanded,
    required this.visible,
    required this.bottomInset,
    required this.selectedVenueId,
    required this.favouriteVenueIds,
    required this.carouselController,
    required this.onToggleExpanded,
    required this.onVenueOpen,
    required this.onFavouriteTap,
    this.onHidden,
  });

  static const Key panelKey = Key('discover-results-panel');
  static const Key panelDecorationKey = Key(
    'discover-results-panel-decoration',
  );
  static const Key slideTransitionKey = Key('discover-results-panel-slide');
  static const Key carouselKey = Key('discover-results-carousel');
  static const Key carouselViewportPaddingKey = Key(
    'discover-results-carousel-viewport-padding',
  );
  static const Key carouselViewportClipKey = Key(
    'discover-results-carousel-viewport-clip',
  );

  static const Duration enterDuration = Duration(milliseconds: 280);
  static const Duration exitDuration = Duration(milliseconds: 240);

  final DiscoverFilter filter;
  final DiscoverLoadState loadState;
  final bool expanded;
  final bool visible;
  final double bottomInset;
  final String? selectedVenueId;
  final Set<String> favouriteVenueIds;
  final ScrollController carouselController;
  final VoidCallback onToggleExpanded;
  final ValueChanged<DiscoverVenueResult> onVenueOpen;
  final ValueChanged<DiscoverVenueResult> onFavouriteTap;
  final VoidCallback? onHidden;

  @override
  State<DiscoverResultsPanel> createState() => _DiscoverResultsPanelState();
}

class _DiscoverResultsPanelState extends State<DiscoverResultsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DiscoverResultsPanel.enterDuration,
      reverseDuration: DiscoverResultsPanel.exitDuration,
    );
    _configureAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.visible) {
        _syncVisibility();
      }
    });
  }

  bool get _reduceMotion =>
      !mounted ? false : MediaQuery.disableAnimationsOf(context);

  void _configureAnimations() {
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _opacity = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant DiscoverResultsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      _syncVisibility();
    }
  }

  Future<void> _syncVisibility() async {
    if (_reduceMotion) {
      _controller.value = widget.visible ? 1 : 0;
      if (!widget.visible) {
        widget.onHidden?.call();
      }
      return;
    }

    if (widget.visible) {
      await _controller.forward();
      return;
    }

    await _controller.reverse();
    if (!mounted) return;
    widget.onHidden?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const collapsedHeight = 72.0;
    const expandedHeight = 304.0;
    final height = widget.expanded ? expandedHeight : collapsedHeight;
    final cardWidth = DiscoverVenueCard.cardWidthForViewport(
      MediaQuery.sizeOf(context).width,
    );

    return AnimatedPositioned(
      key: DiscoverResultsPanel.panelKey,
      duration: _reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: 12,
      right: 12,
      bottom: widget.bottomInset,
      height: height,
      child: SlideTransition(
        key: DiscoverResultsPanel.slideTransitionKey,
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: DecoratedBox(
            key: DiscoverResultsPanel.panelDecorationKey,
            decoration: AppDecorations.heroCard,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppDecorations.heroCardBorderRadius,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      DiscoverCarouselScroll.panelContentPadding,
                      8,
                      6,
                      0,
                    ),
                    child: DiscoverResultsHeader(
                      key: ValueKey('discover-header-${widget.filter.name}'),
                      filter: widget.filter,
                      resultCount: widget.loadState.results.length,
                      expanded: widget.expanded,
                      onToggleExpanded: widget.onToggleExpanded,
                    ),
                  ),
                  if (widget.expanded)
                    Expanded(child: _expandedBody(context, cardWidth)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _showsCarouselItems =>
      widget.loadState.status == DiscoverLoadStatus.success &&
      widget.loadState.results.isNotEmpty;

  Widget _expandedBody(BuildContext context, double cardWidth) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _carousel(cardWidth)),
            if (_showsCarouselItems) const _SearchFooter(),
          ],
        ),
        if (!_showsCarouselItems)
          AnimatedSwitcher(
            duration: _reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(
                'discover-status-${widget.filter.name}-${widget.loadState.status.name}',
              ),
              child: _statusBody(),
            ),
          ),
      ],
    );
  }

  Widget _carousel(double cardWidth) {
    return Padding(
      key: DiscoverResultsPanel.carouselViewportPaddingKey,
      padding: const EdgeInsets.symmetric(
        horizontal: DiscoverCarouselScroll.panelContentPadding,
      ),
      child: ClipRRect(
        key: DiscoverResultsPanel.carouselViewportClipKey,
        borderRadius: BorderRadius.circular(
          DiscoverCarouselScroll.carouselInnerClipRadius,
        ),
        child: ListView.builder(
          key: DiscoverResultsPanel.carouselKey,
          controller: widget.carouselController,
          primary: false,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          physics: _showsCarouselItems
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _showsCarouselItems ? widget.loadState.results.length : 0,
          itemBuilder: (context, index) {
            final result = widget.loadState.results[index];
            return DiscoverVenueCard(
              key: ValueKey('discover-card-${result.venueId}'),
              cardWidth: cardWidth,
              result: result,
              filter: widget.filter,
              selected: widget.selectedVenueId == result.venueId,
              isFavourite: widget.favouriteVenueIds.contains(result.venueId),
              onTap: () => widget.onVenueOpen(result),
              onFavouriteTap: () => widget.onFavouriteTap(result),
            );
          },
        ),
      ),
    );
  }

  Widget _statusBody() {
    switch (widget.loadState.status) {
      case DiscoverLoadStatus.loading:
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case DiscoverLoadStatus.empty:
        return _message(widget.filter.emptyMessage);
      case DiscoverLoadStatus.locationDenied:
        return _message(DiscoverFilter.locationDeniedMessage);
      case DiscoverLoadStatus.locationDisabled:
        return _message(DiscoverFilter.locationDisabledMessage);
      case DiscoverLoadStatus.locationUnavailable:
        return _message(DiscoverFilter.locationUnavailableMessage);
      case DiscoverLoadStatus.error:
        return _message(
          widget.loadState.errorMessage ?? 'Unable to load results right now.',
        );
      case DiscoverLoadStatus.idle:
        return _message('Select a filter to explore venues on the map.');
      case DiscoverLoadStatus.success:
        return _message(widget.filter.emptyMessage);
    }
  }

  Widget _message(String message) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DiscoverCarouselScroll.panelContentPadding,
        8,
        DiscoverCarouselScroll.panelContentPadding,
        16,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _SearchFooter extends StatelessWidget {
  const _SearchFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DiscoverCarouselScroll.panelContentPadding,
        0,
        DiscoverCarouselScroll.panelContentPadding,
        10,
      ),
      child: const Text(
        'Looking for more? Use Search',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
