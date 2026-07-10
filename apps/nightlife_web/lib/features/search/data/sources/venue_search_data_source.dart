import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../../../core/vexcore/web_vexcore.dart';
import '../../../venues/models/venue_model.dart';
import '../../models/venue_search_result.dart';
import '../search_venue_filter.dart';
import '../search_venue_mapper.dart';
import '../venue_search_matcher.dart';
import 'search_data_source.dart';

/// Venue search backed by VexCore discovery services.
class VenueSearchDataSource implements SearchDataSource {
  VenueSearchDataSource({VenueDataService? venueDataService})
    : _venueDataService = venueDataService ?? WebVexCore.venueDataService;

  final VenueDataService _venueDataService;

  @override
  SearchFilterCategory get category => SearchFilterCategory.venues;

  @override
  Future<List<VenueSearchResult>> search({
    required String query,
    required List<VenueSearchResult> catalog,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return List<VenueSearchResult>.from(catalog);

    final firestoreMatches = await _searchDiscoveryIndex(trimmed);
    final matched = <VenueSearchResult>[];
    final seenIds = <String>{};

    for (final venue in catalog) {
      if (seenIds.contains(venue.id)) continue;

      final textMatch = VenueSearchMatcher.matches(venue, trimmed);
      final firestoreMatch = firestoreMatches.contains(venue.id);
      if (!textMatch && !firestoreMatch) continue;

      matched.add(venue);
      seenIds.add(venue.id);
    }

    VenueSearchMatcher.sortByRelevance(matched, trimmed);
    return matched;
  }

  Future<Set<String>> _searchDiscoveryIndex(String query) async {
    final terms = VenueSearchMatcher.termsFromQuery(query);
    if (terms.isEmpty) return const {};

    final result = await _venueDataService.searchDiscoveryVenues(terms: terms);
    return switch (result) {
      DataSuccess(:final value) => value.venueIds,
      DataFailure(:final error) => _logSearchFailure(error),
    };
  }

  Set<String> _logSearchFailure(VexException error) {
    if (kDebugMode) {
      debugPrint('[VenueSearchDataSource] Discovery search failed: $error');
    }
    return const {};
  }

  /// Maps raw Firestore venue docs into search results (used by adapter tests).
  static List<VenueSearchResult> mapDocuments(
    Iterable<MapEntry<String, Map<String, dynamic>>> docs,
  ) {
    final venues = <VenueSearchResult>[];
    for (final doc in docs) {
      final venue = VenueModel.fromMap(doc.key, doc.value);
      final mapped = SearchVenueMapper.fromVenueModel(venue);
      if (mapped != null) {
        venues.add(mapped);
      }
    }
    venues.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return venues;
  }
}
