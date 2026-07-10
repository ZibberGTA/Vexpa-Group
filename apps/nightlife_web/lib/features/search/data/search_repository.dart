import '../models/search_match_models.dart';
import '../models/venue_search_result.dart';
import 'search_venue_catalog.dart';
import 'search_venue_filter.dart';
import 'search_venue_repository.dart';
import 'unified_search_service.dart';

/// Orchestrates unified search through the Discovery Engine and VexCore adapters.
class SearchRepository {
  SearchRepository({
    SearchVenueRepository? venueRepository,
    UnifiedSearchService? unifiedSearchService,
  })  : _venueRepository = venueRepository ?? SearchVenueRepository(),
        _unifiedSearch = unifiedSearchService ?? UnifiedSearchService();

  final SearchVenueRepository _venueRepository;
  final UnifiedSearchService _unifiedSearch;

  List<VenueSearchResult> _catalog = const [];
  bool _usingFallback = false;

  List<VenueSearchResult> get catalog => _catalog;

  bool get usingFallback => _usingFallback;

  Future<SearchVenueCatalog> loadCatalog() async {
    final loaded = await _venueRepository.loadVenues();
    _catalog = loaded.venues;
    _usingFallback = loaded.usingFallback;
    return loaded;
  }

  /// Runs unified search across venues, drinks, deals, events and trails.
  Future<UnifiedSearchResponse> search({
    required String query,
    required SearchFilterCategory category,
  }) async {
    return _unifiedSearch.search(
      query: query,
      catalog: _catalog,
      category: category,
      usingFallback: _usingFallback,
    );
  }

  static int resolveSelection({
    required int currentIndex,
    required List<int> filteredIndices,
  }) {
    return SearchVenueFilter.resolveSelection(
      currentIndex: currentIndex,
      filteredIndices: filteredIndices,
    );
  }
}
