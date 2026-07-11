import 'package:test/test.dart';
import 'package:vex_engines/discovery/application/discovery_nearby_sorter.dart';
import 'package:vex_engines/discovery/application/discovery_search_result_rules.dart';
import 'package:vex_engines/discovery/application/discovery_trending_scorer.dart';
import 'package:vex_engines/discovery/application/discovery_venue_client_matcher.dart';
import 'package:vex_engines/discovery/domain/discovery_venue_catalog_entry.dart';
import 'package:vex_engines/discovery/domain/discovery_venue_filter_state.dart';
import 'package:vex_engines/discovery/shared/discovery_map_geometry.dart';
import 'package:vex_engines/discovery/shared/discovery_query_normalizer.dart';
import 'package:vex_engines/discovery/shared/discovery_venue_search_term_builder.dart';
import 'package:vex_engines/discovery/shared/venue_search_matcher.dart';
import 'package:vex_engines/discovery/domain/discovery_venue_searchable.dart';

final class _SearchableVenue implements DiscoveryVenueSearchable {
  const _SearchableVenue({
    required this.name,
    this.city = '',
    this.area = '',
    this.postcode = '',
    this.venueType = '',
    this.tags = const [],
  });

  final String name;
  @override
  final String city;
  @override
  final String area;
  @override
  final String postcode;
  @override
  final String venueType;
  @override
  final List<String> tags;
}

void main() {
  group('DiscoveryQueryNormalizer', () {
    test('expands whisky and whiskey aliases', () {
      expect(
        DiscoveryQueryNormalizer.expandAliases('whisky'),
        containsAll(['whisky', 'whiskey']),
      );
      expect(
        DiscoveryQueryNormalizer.expandAliases('whiskey'),
        containsAll(['whisky', 'whiskey']),
      );
    });

    test('matchesAny supports contains and exact', () {
      expect(
        DiscoveryQueryNormalizer.matchesAny('old fashioned', ['old']),
        isTrue,
      );
      expect(
        DiscoveryQueryNormalizer.matchesAny('bar', ['club']),
        isFalse,
      );
    });
  });

  group('VenueSearchMatcher parity', () {
    test('matches whisky alias on venue tags', () {
      const venue = _SearchableVenue(
        name: 'Spirit Room',
        tags: ['whiskey'],
      );

      expect(VenueSearchMatcher.matches(venue, 'whisky'), isTrue);
    });

    test('empty query matches all venues', () {
      const venue = _SearchableVenue(name: 'Any Bar');
      expect(VenueSearchMatcher.matches(venue, ''), isTrue);
    });

    test('sorts by exact name before prefix before contains', () {
      final venues = [
        const _SearchableVenue(name: 'Neon Bar'),
        const _SearchableVenue(name: 'Bar Neon'),
        const _SearchableVenue(name: 'Neon'),
      ];

      VenueSearchMatcher.sortByRelevance(venues, 'neon');

      expect(venues.first.name, 'Neon');
      expect(venues[1].name, 'Neon Bar');
    });
  });

  group('DiscoveryVenueSearchTermBuilder', () {
    test('buildVenueIndexTerms splits tokens and applies whisky alias', () {
      final terms = DiscoveryVenueSearchTermBuilder.buildVenueIndexTerms(
        venueName: 'Whisky Lounge',
        category: 'Bar',
        drinks: ['Old Fashioned'],
      );

      expect(terms, contains('whisky'));
      expect(terms, contains('whiskey'));
      expect(terms, contains('lounge'));
      expect(terms, contains('fashioned'));
    });

    test('buildVenueFormTerms deduplicates whitespace tokens', () {
      final terms = DiscoveryVenueSearchTermBuilder.buildVenueFormTerms(
        name: 'Neon  Room',
        description: 'Late night bar',
        address: '12 Brick Lane',
        category: 'Bar',
        crowdLevel: 'busy',
      );

      expect(terms, contains('neon'));
      expect(terms, contains('room'));
      expect(terms.toSet().length, terms.length);
    });

    test('buildFromFieldValues removes empty values', () {
      final terms = DiscoveryVenueSearchTermBuilder.buildFromFieldValues([
        ' Deal ',
        '',
        'Bar',
        'bar',
      ]);

      expect(terms, ['deal', 'bar']);
    });
  });

  group('DiscoveryVenueClientMatcher', () {
    const catalogVenue = DiscoveryVenueCatalogEntry(
      name: 'Whisky House',
      category: 'Bar',
      crowdLevel: 'busy',
      address: '12 Soho Street',
      searchTerms: ['old fashioned', 'whiskey sour'],
    );

    test('returns match reasons for alias query', () {
      final reasons = DiscoveryVenueClientMatcher.matchReasons(
        venue: catalogVenue,
        query: 'whisky',
      );

      expect(reasons, contains('Venue name'));
    });

    test('filters and ranks exact name matches first', () {
      final venues = [
        const _CatalogVenue(id: '1', name: 'Neon Bar'),
        const _CatalogVenue(id: '2', name: 'Neon'),
        const _CatalogVenue(id: '3', name: 'Other Place'),
      ];

      final matched = DiscoveryVenueClientMatcher.filterWithReasons(
        items: venues,
        query: 'neon',
        toEntry: (venue) => venue.entry,
        withReasons: (venue, reasons) =>
            venue.copyWith(matchReasons: reasons),
      );

      expect(matched.length, 2);
      expect(matched.first.name, 'Neon');
    });

    test('returns all venues for empty query without reasons', () {
      final venues = [
        const _CatalogVenue(id: '1', name: 'A'),
        const _CatalogVenue(id: '2', name: 'B'),
      ];

      final matched = DiscoveryVenueClientMatcher.filterWithReasons(
        items: venues,
        query: '',
        toEntry: (venue) => venue.entry,
        withReasons: (venue, reasons) =>
            venue.copyWith(matchReasons: reasons),
      );

      expect(matched.length, 2);
      expect(matched.every((venue) => venue.matchReasons.isEmpty), isTrue);
    });

    test('handles malformed empty venue fields', () {
      const venue = DiscoveryVenueCatalogEntry(
        name: '',
        category: '',
        crowdLevel: '',
        address: '',
        searchTerms: const [],
      );

      final reasons = DiscoveryVenueClientMatcher.matchReasons(
        venue: venue,
        query: 'bar',
      );

      expect(reasons, isEmpty);
    });
  });

  group('DiscoveryBoostEvaluator', () {
    test('treats expired boosts as inactive', () {
      final now = DateTime(2026, 1, 1, 12);

      expect(
        DiscoveryBoostEvaluator.isBoostActive(
          active: true,
          endsAt: DateTime(2026, 1, 1, 11),
          now: now,
        ),
        isFalse,
      );
    });

    test('treats active boosts without end date as active', () {
      expect(
        DiscoveryBoostEvaluator.isBoostActive(active: true),
        isTrue,
      );
    });
  });

  group('DiscoveryNearbySorter', () {
    test('orders venues by distance when user location exists', () {
      final venues = [
        _GeoVenue(id: 'far', lat: 53.0, lng: -1.0),
        _GeoVenue(id: 'near', lat: 51.51, lng: -0.12),
      ];

      DiscoveryNearbySorter.sortByNearby(
        items: venues,
        userLatitude: 51.5,
        userLongitude: -0.1,
        readVenueLatitude: (venue) => venue.lat,
        readVenueLongitude: (venue) => venue.lng,
        readFallbackScore: (_) => 0,
      );

      expect(venues.first.id, 'near');
    });

    test('uses fallback popularity score without location', () {
      final venues = [
        _GeoVenue(id: 'quiet', lat: null, lng: null, score: 1),
        _GeoVenue(id: 'busy-deals', lat: null, lng: null, score: 9),
      ];

      DiscoveryNearbySorter.sortByNearby(
        items: venues,
        userLatitude: null,
        userLongitude: null,
        readVenueLatitude: (venue) => venue.lat,
        readVenueLongitude: (venue) => venue.lng,
        readFallbackScore: (venue) => venue.score,
      );

      expect(venues.first.id, 'busy-deals');
    });

    test('breaks distance ties deterministically via stable sort order', () {
      final venues = [
        _GeoVenue(id: 'b', lat: 51.51, lng: -0.12),
        _GeoVenue(id: 'a', lat: 51.51, lng: -0.12),
      ];

      DiscoveryNearbySorter.sortByNearby(
        items: venues,
        userLatitude: 51.5,
        userLongitude: -0.1,
        readVenueLatitude: (venue) => venue.lat,
        readVenueLongitude: (venue) => venue.lng,
        readFallbackScore: (_) => 0,
      );

      expect(venues.first.id, 'b');
    });
  });

  group('DiscoveryVenueFilterState', () {
    test('detects active filters', () {
      expect(
        const DiscoveryVenueFilterState(searchText: 'bar').hasActiveFilters,
        isTrue,
      );
      expect(
        const DiscoveryVenueFilterState(category: 'Pub').hasActiveFilters,
        isTrue,
      );
      expect(
        const DiscoveryVenueFilterState(dealsOnly: true).hasActiveFilters,
        isTrue,
      );
      expect(
        const DiscoveryVenueFilterState().hasActiveFilters,
        isFalse,
      );
    });
  });

  group('DiscoveryMapGeometry', () {
    test('centroid averages coordinates', () {
      final centroid = DiscoveryMapGeometry.centroid([
        const DiscoveryCoordinate(latitude: 51.0, longitude: -0.1),
        const DiscoveryCoordinate(latitude: 53.0, longitude: -1.0),
      ]);

      expect(centroid!.latitude, 52.0);
      expect(centroid.longitude, -0.55);
    });

    test('rejects invalid coordinates', () {
      expect(
        DiscoveryMapGeometry.isValidCoordinate(double.nan, 0),
        isFalse,
      );
      expect(
        DiscoveryMapGeometry.isValidCoordinate(91, 0),
        isFalse,
      );
    });
  });

  group('DiscoverySearchResultRules', () {
    test('prefers feature tags over category fallback', () {
      final tags = DiscoverySearchResultRules.resolveTags(
        featureTags: const ['Cocktails'],
        venueType: 'Bar',
        category: 'Pub',
      );

      expect(tags, ['Cocktails']);
    });

    test('returns happy hour reason when deals exist', () {
      expect(
        DiscoverySearchResultRules.resultReasonFor(
          hasDeals: true,
          featureTags: const [],
          venueType: 'Bar',
          category: 'Pub',
        ),
        'Happy Hour active',
      );
    });
  });
}

final class _CatalogVenue {
  const _CatalogVenue({
    required this.id,
    required this.name,
    this.matchReasons = const [],
  });

  final String id;
  final String name;
  final List<String> matchReasons;

  DiscoveryVenueCatalogEntry get entry => DiscoveryVenueCatalogEntry(
    name: name,
    category: 'Bar',
    crowdLevel: 'busy',
    address: 'London',
    searchTerms: const [],
  );

  _CatalogVenue copyWith({List<String>? matchReasons}) {
    return _CatalogVenue(
      id: id,
      name: name,
      matchReasons: matchReasons ?? this.matchReasons,
    );
  }
}

final class _GeoVenue {
  const _GeoVenue({
    required this.id,
    required this.lat,
    required this.lng,
    this.score = 0,
  });

  final String id;
  final double? lat;
  final double? lng;
  final int score;
}
