import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../../core/vexcore/vex_venue_mapper.dart';
import '../../../core/vexcore/web_vexcore.dart';
import '../models/venue_search_result.dart';
import 'search_venue_catalog.dart';
import 'search_venue_mapper.dart';

/// Loads the public venue discovery catalog through VexCore.
class SearchVenueRepository {
  SearchVenueRepository({VenueDataService? venueDataService})
    : _venueDataService = venueDataService ?? WebVexCore.venueDataService;

  final VenueDataService _venueDataService;

  Future<SearchVenueCatalog> loadVenues() async {
    final result = await _venueDataService.loadDiscoveryCatalog();
    return switch (result) {
      DataSuccess(:final value) => _mapCatalog(value.venues),
      DataFailure() => _fallbackCatalog(reason: 'Venue catalog load failed'),
    };
  }

  SearchVenueCatalog _mapCatalog(List<Venue> venues) {
    final mapped = <VenueSearchResult>[];
    var skippedWithoutCoordinates = 0;

    for (final venue in venues) {
      final model = venueModelFromVexVenue(venue);
      final searchResult = SearchVenueMapper.fromVenueModel(model);
      if (searchResult != null) {
        mapped.add(searchResult);
      } else {
        skippedWithoutCoordinates++;
      }
    }

    if (mapped.isEmpty) {
      return _fallbackCatalog(
        reason: venues.isEmpty
            ? 'Venue catalog returned no venue documents'
            : 'Venue catalog returned no venues with valid latitude/longitude '
                '($skippedWithoutCoordinates skipped)',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[SearchVenueRepository] Loaded ${mapped.length} venues '
        '($skippedWithoutCoordinates skipped without coordinates).',
      );
    }

    return SearchVenueCatalog(
      venues: mapped,
      usingFallback: false,
    );
  }

  SearchVenueCatalog _fallbackCatalog({required String reason}) {
    if (kDebugMode) {
      debugPrint('[SearchVenueRepository] Using mock fallback: $reason');
    }
    return SearchVenueCatalog(
      venues: SearchVenueMapper.fallbackVenues(),
      usingFallback: true,
    );
  }
}
