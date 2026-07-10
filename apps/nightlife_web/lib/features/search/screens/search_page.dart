import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../home/widgets/home_nav_bar.dart';
import '../data/search_repository.dart';
import '../data/search_venue_catalog.dart';
import '../data/search_venue_filter.dart';
import '../models/search_match_models.dart';
import '../models/venue_search_result.dart';
import '../widgets/search_floating_bar.dart';
import '../widgets/search_google_map.dart';
import '../widgets/search_results_panel.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final SearchRepository _repository = SearchRepository();
  late final Future<SearchVenueCatalog> _catalogFuture;

  Timer? _searchDebounceTimer;
  int _searchRequestId = 0;

  int _selectedVenueIndex = 0;
  String _searchQuery = '';
  SearchFilterCategory _activeFilter = SearchFilterCategory.venues;
  UnifiedSearchResponse _searchResponse = UnifiedSearchResponse.empty;
  bool _catalogInitialized = false;

  @override
  void initState() {
    super.initState();
    _catalogFuture = _repository.loadCatalog();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCatalog(List<VenueSearchResult> venues) async {
    if (_catalogInitialized) return;
    _catalogInitialized = true;
    await _runSearch(venues);
  }

  Future<void> _runSearch(List<VenueSearchResult> venues) async {
    final requestId = ++_searchRequestId;
    final response = await _repository.search(
      query: _searchQuery,
      category: _activeFilter,
    );

    if (!mounted || requestId != _searchRequestId) return;

    final indices = response.catalogIndices;
    setState(() {
      _searchResponse = response;
      _selectedVenueIndex = SearchRepository.resolveSelection(
        currentIndex: _selectedVenueIndex,
        filteredIndices: indices,
      );
    });
  }

  void _scheduleSearch(List<VenueSearchResult> venues) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      _runSearch(venues);
    });
  }

  void _onVenueSelected(int index) {
    if (index < 0 || _selectedVenueIndex == index) return;
    setState(() => _selectedVenueIndex = index);
  }

  void _onSearchQueryChanged(String query, List<VenueSearchResult> venues) {
    setState(() => _searchQuery = query);
    _scheduleSearch(venues);
  }

  void _onFilterChanged(
    SearchFilterCategory category,
    List<VenueSearchResult> venues,
  ) {
    if (_activeFilter == category) return;
    setState(() => _activeFilter = category);
    _searchDebounceTimer?.cancel();
    _runSearch(venues);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SearchVenueCatalog>(
      future: _catalogFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            ),
          );
        }

        final catalog = snapshot.data!;
        final venues = catalog.venues;

        if (!_catalogInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeCatalog(venues);
          });
        }

        final filteredVenueIndices = _searchResponse.catalogIndices;
        final searchMatches = _searchResponse.matches;
        final isMobile = Breakpoints.isMobile(context);
        final layout = _SearchMapLayout.of(context);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: SearchGoogleMap(
                  venues: venues,
                  selectedIndex: _selectedVenueIndex,
                  visibleVenueIndices: filteredVenueIndices,
                  onPinSelected: _onVenueSelected,
                  padding: layout.mapPadding,
                ),
              ),
              if (isMobile)
                _MobileSearchOverlay(
                  layout: layout,
                  venues: venues,
                  selectedIndex: _selectedVenueIndex,
                  onVenueSelected: _onVenueSelected,
                  searchQuery: _searchQuery,
                  onSearchQueryChanged: (query) =>
                      _onSearchQueryChanged(query, venues),
                  filteredVenueIndices: filteredVenueIndices,
                  searchMatches: searchMatches,
                  groupCounts: _searchResponse.groupCounts,
                  activeFilter: _activeFilter,
                  onFilterChanged: (category) =>
                      _onFilterChanged(category, venues),
                )
              else
                _DesktopSearchOverlay(
                  layout: layout,
                  venues: venues,
                  selectedIndex: _selectedVenueIndex,
                  onVenueSelected: _onVenueSelected,
                  searchQuery: _searchQuery,
                  onSearchQueryChanged: (query) =>
                      _onSearchQueryChanged(query, venues),
                  filteredVenueIndices: filteredVenueIndices,
                  searchMatches: searchMatches,
                  groupCounts: _searchResponse.groupCounts,
                  activeFilter: _activeFilter,
                  onFilterChanged: (category) =>
                      _onFilterChanged(category, venues),
                ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HomeNavBar(activeRoute: AppRouter.map),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Overlay spacing and map insets for the search map page.
class _SearchMapLayout {
  const _SearchMapLayout({
    required this.horizontalInset,
    required this.overlayTop,
    required this.searchBarHeight,
    required this.panelWidth,
    required this.panelTop,
    required this.panelBottom,
    required this.mapPadding,
  });

  final double horizontalInset;
  final double overlayTop;
  final double searchBarHeight;
  final double panelWidth;
  final double panelTop;
  final double panelBottom;
  final EdgeInsets mapPadding;

  static const double _searchBelowNav = AppSpacing.md;
  static const double _panelBelowSearch = AppSpacing.lg;
  static const double _panelBottomInset = AppSpacing.xl;
  static const double _mapEdgeInset = AppSpacing.lg;
  static const double _mobilePanelHeight = 240;

  static _SearchMapLayout of(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final horizontalInset = Breakpoints.horizontalPadding(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final navBottom = safeTop + Breakpoints.reservedNavHeight(context);
    final overlayTop = navBottom + _searchBelowNav;
    final searchBarHeight = _searchBarHeightFor(context);
    final panelWidth = _resultsPanelWidth(context);
    final panelTop = overlayTop + searchBarHeight + _panelBelowSearch;
    final panelBottom = _panelBottomInset;

    final mapPadding = isMobile
        ? EdgeInsets.fromLTRB(
            horizontalInset,
            panelTop + _mobilePanelHeight + _mapEdgeInset,
            horizontalInset,
            _mapEdgeInset,
          )
        : EdgeInsets.fromLTRB(
            horizontalInset + panelWidth + _mapEdgeInset,
            panelTop,
            horizontalInset,
            panelBottom,
          );

    return _SearchMapLayout(
      horizontalInset: horizontalInset,
      overlayTop: overlayTop,
      searchBarHeight: searchBarHeight,
      panelWidth: panelWidth,
      panelTop: panelTop,
      panelBottom: panelBottom,
      mapPadding: mapPadding,
    );
  }

  static double _searchBarHeightFor(BuildContext context) {
    return switch (Breakpoints.of(context)) {
      ScreenSize.desktop => 68,
      ScreenSize.tablet => 64,
      ScreenSize.mobile => 58,
    };
  }

  static double _resultsPanelWidth(BuildContext context) {
    return switch (Breakpoints.of(context)) {
      ScreenSize.desktop => 360,
      ScreenSize.tablet => 288,
      ScreenSize.mobile => double.infinity,
    };
  }
}

class _DesktopSearchOverlay extends StatelessWidget {
  const _DesktopSearchOverlay({
    required this.layout,
    required this.venues,
    required this.selectedIndex,
    required this.onVenueSelected,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.filteredVenueIndices,
    required this.searchMatches,
    required this.groupCounts,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final _SearchMapLayout layout;
  final List<VenueSearchResult> venues;
  final int selectedIndex;
  final ValueChanged<int> onVenueSelected;
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;
  final List<int> filteredVenueIndices;
  final List<SearchVenueMatch> searchMatches;
  final SearchGroupCounts groupCounts;
  final SearchFilterCategory activeFilter;
  final ValueChanged<SearchFilterCategory> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: layout.overlayTop,
          left: layout.horizontalInset,
          right: layout.horizontalInset,
          child: SearchFloatingBar(onQueryChanged: onSearchQueryChanged),
        ),
        Positioned(
          top: layout.panelTop,
          left: layout.horizontalInset,
          bottom: layout.panelBottom,
          width: layout.panelWidth,
          child: SearchResultsPanel(
            venues: venues,
            selectedIndex: selectedIndex,
            onVenueSelected: onVenueSelected,
            searchQuery: searchQuery,
            filteredVenueIndices: filteredVenueIndices,
            searchMatches: searchMatches,
            groupCounts: groupCounts,
            activeFilter: activeFilter,
            onFilterChanged: onFilterChanged,
          ),
        ),
      ],
    );
  }
}

class _MobileSearchOverlay extends StatelessWidget {
  const _MobileSearchOverlay({
    required this.layout,
    required this.venues,
    required this.selectedIndex,
    required this.onVenueSelected,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.filteredVenueIndices,
    required this.searchMatches,
    required this.groupCounts,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final _SearchMapLayout layout;
  final List<VenueSearchResult> venues;
  final int selectedIndex;
  final ValueChanged<int> onVenueSelected;
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;
  final List<int> filteredVenueIndices;
  final List<SearchVenueMatch> searchMatches;
  final SearchGroupCounts groupCounts;
  final SearchFilterCategory activeFilter;
  final ValueChanged<SearchFilterCategory> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: layout.overlayTop,
          left: layout.horizontalInset,
          right: layout.horizontalInset,
          child: SearchFloatingBar(onQueryChanged: onSearchQueryChanged),
        ),
        Positioned(
          top: layout.panelTop,
          left: layout.horizontalInset,
          right: layout.horizontalInset,
          height: _SearchMapLayout._mobilePanelHeight,
          child: SearchResultsPanel(
            venues: venues,
            selectedIndex: selectedIndex,
            onVenueSelected: onVenueSelected,
            searchQuery: searchQuery,
            filteredVenueIndices: filteredVenueIndices,
            searchMatches: searchMatches,
            groupCounts: groupCounts,
            activeFilter: activeFilter,
            onFilterChanged: onFilterChanged,
          ),
        ),
      ],
    );
  }
}
