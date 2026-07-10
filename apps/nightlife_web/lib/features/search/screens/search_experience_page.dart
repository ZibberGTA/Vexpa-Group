import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/public_loading_state.dart';
import '../../../shared/components/public_page_hero.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../data/search_repository.dart';
import '../data/search_venue_catalog.dart';
import '../data/search_venue_filter.dart';
import '../models/search_match_models.dart';
import '../models/venue_search_result.dart';
import '../widgets/search_floating_bar.dart';
import '../widgets/search_results_panel.dart';

/// Dedicated search experience without the map — unified search architecture.
class SearchExperiencePage extends StatefulWidget {
  const SearchExperiencePage({super.key});

  @override
  State<SearchExperiencePage> createState() => _SearchExperiencePageState();
}

class _SearchExperiencePageState extends State<SearchExperiencePage> {
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

    setState(() {
      _searchResponse = response;
      _selectedVenueIndex = SearchRepository.resolveSelection(
        currentIndex: _selectedVenueIndex,
        filteredIndices: response.catalogIndices,
      );
    });
  }

  void _scheduleSearch(List<VenueSearchResult> venues) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () => _runSearch(venues));
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      navActiveRoute: AppRouter.search,
      child: FutureBuilder<SearchVenueCatalog>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PublicPageHero(
                eyebrow: 'Unified search',
                title: AppStrings.searchPageTitle,
                subtitle: AppStrings.searchPageSubtitle,
                trailing: ContentContainer(
                  child: SearchFloatingBar(
                    onQueryChanged: (query) {
                      if (!snapshot.hasData) return;
                      setState(() => _searchQuery = query);
                      _scheduleSearch(snapshot.data!.venues);
                    },
                  ),
                ),
              ),
              if (!snapshot.hasData)
                const SizedBox(
                  height: 420,
                  child: PublicLoadingState(message: 'Loading search catalog…'),
                )
              else
                Builder(
                  builder: (context) {
                    final venues = snapshot.data!.venues;
                    if (!_catalogInitialized) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _initializeCatalog(venues);
                      });
                    }

                    final isMobile = Breakpoints.isMobile(context);
                    final panelHeight = isMobile ? 520.0 : 640.0;

                    return ContentContainer(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                        child: SizedBox(
                          height: panelHeight,
                          child: SearchResultsPanel(
                            venues: venues,
                            selectedIndex: _selectedVenueIndex,
                            onVenueSelected: (index) {
                              setState(() => _selectedVenueIndex = index);
                            },
                            searchQuery: _searchQuery,
                            filteredVenueIndices: _searchResponse.catalogIndices,
                            searchMatches: _searchResponse.matches,
                            groupCounts: _searchResponse.groupCounts,
                            activeFilter: _activeFilter,
                            onFilterChanged: (category) {
                              setState(() => _activeFilter = category);
                              _searchDebounceTimer?.cancel();
                              _runSearch(venues);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ContentContainer(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  child: _PlaceholderSection(
                    title: 'Tonight\'s picks',
                    message:
                        'Curated discovery sections will surface trending venues, events and trails here.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
