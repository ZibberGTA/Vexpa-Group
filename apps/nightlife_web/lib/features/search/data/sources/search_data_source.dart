import '../../models/venue_search_result.dart';
import '../search_venue_filter.dart';

/// Contract for category-specific Firestore search providers.
///
/// Drinks, deals, events and trails will implement this in later phases.
abstract class SearchDataSource {
  SearchFilterCategory get category;

  Future<List<VenueSearchResult>> search({
    required String query,
    required List<VenueSearchResult> catalog,
  });
}
