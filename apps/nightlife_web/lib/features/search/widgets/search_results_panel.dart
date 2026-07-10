import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/search_match_models.dart';
import '../models/venue_search_result.dart';
import '../data/search_venue_filter.dart';
import 'venue_result_card.dart';

/// Floating glass search results panel with premium venue cards.
class SearchResultsPanel extends StatefulWidget {
  const SearchResultsPanel({
    super.key,
    required this.venues,
    required this.selectedIndex,
    required this.onVenueSelected,
    required this.filteredVenueIndices,
    required this.searchMatches,
    required this.groupCounts,
    required this.activeFilter,
    required this.onFilterChanged,
    this.searchQuery = '',
  });

  final List<VenueSearchResult> venues;
  final int selectedIndex;
  final ValueChanged<int> onVenueSelected;
  final List<int> filteredVenueIndices;
  final List<SearchVenueMatch> searchMatches;
  final SearchGroupCounts groupCounts;
  final SearchFilterCategory activeFilter;
  final ValueChanged<SearchFilterCategory> onFilterChanged;
  final String searchQuery;

  @override
  State<SearchResultsPanel> createState() => _SearchResultsPanelState();
}

class _SearchResultsPanelState extends State<SearchResultsPanel> {
  List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _syncItemKeys();
  }

  @override
  void didUpdateWidget(covariant SearchResultsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venues.length != widget.venues.length) {
      _syncItemKeys();
    }
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelectedCard();
    }
  }

  void _syncItemKeys() {
    _itemKeys = List.generate(widget.venues.length, (_) => GlobalKey());
  }

  void _scrollToSelectedCard() {
    if (widget.selectedIndex < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.selectedIndex < 0 ||
          widget.selectedIndex >= _itemKeys.length) {
        return;
      }
      final itemContext = _itemKeys[widget.selectedIndex].currentContext;
      if (itemContext == null) return;

      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.filteredVenueIndices;
    final isEmpty = filtered.isEmpty;

    return _SearchResultsPanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultsHeader(
            searchQuery: widget.searchQuery,
            resultCount: filtered.length,
            groupCounts: widget.groupCounts,
          ),
          if (widget.searchQuery.trim().isNotEmpty &&
              !widget.groupCounts.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _SearchGroupCountsRow(groupCounts: widget.groupCounts),
          ],
          const SizedBox(height: AppSpacing.xl),
          _FilterChipRow(
            activeFilter: widget.activeFilter,
            onFilterChanged: widget.onFilterChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: isEmpty
                ? _SearchEmptyState(
                    hasSearchQuery: widget.searchQuery.trim().isNotEmpty,
                    activeFilter: widget.activeFilter,
                  )
                : ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: true,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      itemCount: widget.searchMatches.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, listIndex) {
                        final match = widget.searchMatches[listIndex];
                        final venueIndex = match.catalogIndex;
                        return KeyedSubtree(
                          key: _itemKeys[venueIndex],
                          child: VenueResultCard(
                            venue: match.venue,
                            selected: widget.selectedIndex == venueIndex,
                            matchLine: match.matchLine,
                            onTap: () {
                              widget.onVenueSelected(venueIndex);
                              Navigator.of(context).pushNamed(
                                AppRouter.venueDetails(match.venue.id),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Premium glass shell tuned for the search results panel.
class _SearchResultsPanelShell extends StatelessWidget {
  const _SearchResultsPanelShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.12),
            blurRadius: 52,
            spreadRadius: -14,
          ),
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.06),
            blurRadius: 28,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.11),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.searchQuery,
    required this.resultCount,
    required this.groupCounts,
  });

  final String searchQuery;
  final int resultCount;
  final SearchGroupCounts groupCounts;

  @override
  Widget build(BuildContext context) {
    final trimmed = searchQuery.trim();
    final hasQuery = trimmed.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
        ),
        if (hasQuery) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Results for "$trimmed"',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryPink.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Showing all venues',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$resultCount venue${resultCount == 1 ? '' : 's'} found',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _SearchGroupCountsRow extends StatelessWidget {
  const _SearchGroupCountsRow({required this.groupCounts});

  final SearchGroupCounts groupCounts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final group in groupCounts.nonEmptyGroups)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              '${group.label} (${group.count})',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.hasSearchQuery,
    required this.activeFilter,
  });

  final bool hasSearchQuery;
  final SearchFilterCategory activeFilter;

  @override
  Widget build(BuildContext context) {
    final isVenueSearch =
        activeFilter == SearchFilterCategory.venues ||
        activeFilter == SearchFilterCategory.openNow;

    final title = hasSearchQuery && isVenueSearch
        ? 'No venues found'
        : 'No Vexda venues found';

    final subtitle = hasSearchQuery && isVenueSearch
        ? 'Try searching for another venue or location.'
        : 'Try searching for a venue, drink, city, event or trail.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 36,
              color: AppColors.primaryPurple.withValues(alpha: 0.65),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final SearchFilterCategory activeFilter;
  final ValueChanged<SearchFilterCategory> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SearchFilterCategory.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = SearchFilterCategory.all[index];
          final active = activeFilter == category;

          return _FilterChip(
            label: category.label,
            active: active,
            compact: isMobile,
            onTap: () => onFilterChanged(category),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final hovered = _hovered && !active;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            gradient: active ? AppColors.brandGradient : null,
            color: active
                ? null
                : AppColors.surfaceElevated.withValues(
                    alpha: hovered ? 0.88 : 0.75,
                  ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? AppColors.primaryPink.withValues(alpha: 0.85)
                  : hovered
                      ? AppColors.primaryPurple.withValues(alpha: 0.55)
                      : AppColors.border.withValues(alpha: 0.45),
              width: active ? 1.4 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.22),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: active
                  ? AppColors.white
                  : hovered
                      ? AppColors.white.withValues(alpha: 0.92)
                      : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
            ),
          ),
        ),
      ),
    );
  }
}
