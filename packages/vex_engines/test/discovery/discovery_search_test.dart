import 'package:test/test.dart';
import 'package:vex_engines/discovery/application/discovery_unified_search_composer.dart';
import 'package:vex_engines/discovery/application/discovery_venue_search_service.dart';
import 'package:vex_engines/discovery/application/search_ranking.dart';
import 'package:vex_engines/discovery/domain/discovery_rankable_match.dart';
import 'package:vex_engines/discovery/domain/discovery_venue_searchable.dart';
import 'package:vex_engines/discovery/domain/search_filter_category.dart';
import 'package:vex_engines/discovery/domain/search_match_models.dart';
import 'package:vex_engines/discovery/shared/search_text_utils.dart';
import 'package:vex_engines/discovery/shared/venue_search_matcher.dart';

final class _TestVenue implements DiscoveryVenueMatchable {
  const _TestVenue({
    required this.id,
    required this.name,
    this.city = 'London',
    this.area = 'Shoreditch',
    this.postcode = 'E1 6PU',
    this.venueType = 'Bar',
    this.tags = const [],
    this.isOpen = true,
  });

  @override
  final String id;

  @override
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

  @override
  final bool isOpen;
}

final class _TestMatch implements DiscoveryRankableMatch {
  const _TestMatch({
    required this.venue,
    this.directVenueMatch = false,
    this.matchedDrinks = const [],
    this.matchedDeals = const [],
    this.matchedEvents = const [],
    this.matchedTrails = const [],
    this.rankScore = 0,
  });

  @override
  final _TestVenue venue;

  @override
  final bool directVenueMatch;

  @override
  final List<MatchedDrink> matchedDrinks;

  @override
  final List<MatchedDeal> matchedDeals;

  @override
  final List<MatchedEvent> matchedEvents;

  @override
  final List<MatchedTrail> matchedTrails;

  @override
  final int rankScore;
}

void main() {
  group('SearchTextUtils', () {
    test('normalises and tokenises queries', () {
      expect(SearchTextUtils.normalise('  Neon Room '), 'neon room');
      expect(SearchTextUtils.termsFromQuery('The Neon Room'), [
        'the',
        'neon',
        'room',
      ]);
    });

    test('containsQuery matches nested values', () {
      expect(
        SearchTextUtils.containsQuery(['Espresso', 'Martini'], 'press'),
        isTrue,
      );
      expect(SearchTextUtils.containsQuery(null, 'test'), isFalse);
    });
  });

  group('VenueSearchMatcher', () {
    test('matches venue fields case-insensitively', () {
      const venue = _TestVenue(id: '1', name: 'The Neon Room', city: 'London');

      expect(VenueSearchMatcher.matches(venue, 'neon'), isTrue);
      expect(VenueSearchMatcher.matches(venue, 'paris'), isFalse);
    });

    test('sorts by relevance', () {
      final venues = [
        const _TestVenue(id: '1', name: 'Harbour Bar'),
        const _TestVenue(id: '2', name: 'Neon Room'),
        const _TestVenue(id: '3', name: 'Neon Lounge'),
      ];

      VenueSearchMatcher.sortByRelevance(venues, 'neon');
      expect(venues.map((venue) => venue.id).toList(), ['3', '2', '1']);
    });
  });

  group('DiscoveryVenueSearchService', () {
    const service = DiscoveryVenueSearchService();

    test('returns full catalog for empty query', () {
      const catalog = [
        _TestVenue(id: '1', name: 'Alpha'),
        _TestVenue(id: '2', name: 'Beta'),
      ];

      expect(
        service.composeVenueMatches(
          query: '',
          catalog: catalog,
          indexMatchedIds: const {},
        ),
        catalog,
      );
    });

    test('merges text and index matches without duplicates', () {
      const catalog = [
        _TestVenue(id: '1', name: 'Neon Room'),
        _TestVenue(id: '2', name: 'Pulse Bar'),
      ];

      final matched = service.composeVenueMatches(
        query: 'neon',
        catalog: catalog,
        indexMatchedIds: const {'2'},
      );

      expect(matched.map((venue) => venue.id).toList(), ['1', '2']);
    });
  });

  group('DiscoveryUnifiedSearchComposer', () {
    const composer = DiscoveryUnifiedSearchComposer();

    test('filters open now venues for empty query', () {
      final venues = composer.composeAllVenueMatches(
        catalog: const [
          _TestVenue(id: '1', name: 'Open', isOpen: true),
          _TestVenue(id: '2', name: 'Closed', isOpen: false),
        ],
        category: SearchFilterCategory.openNow,
        buildMatch: (index, venue) => venue,
      );

      expect(venues.length, 1);
      expect(venues.first.id, '1');
    });

    test('ranks and filters unified matches by category', () {
      const neon = _TestVenue(id: '1', name: 'Neon Room');
      const pulse = _TestVenue(id: '2', name: 'Pulse Bar');

      final composed = composer.composeResponse(
        groupedMatches: [
          _TestMatch(
            venue: neon,
            directVenueMatch: true,
            matchedDrinks: const [
              MatchedDrink(id: 'd1', name: 'Espresso Martini'),
            ],
          ),
          const _TestMatch(venue: pulse, directVenueMatch: true),
        ],
        query: 'neon',
        category: SearchFilterCategory.drinks,
        withRankScore: (match, rankScore) => _TestMatch(
          venue: match.venue,
          directVenueMatch: match.directVenueMatch,
          matchedDrinks: match.matchedDrinks,
          rankScore: rankScore,
        ),
      );

      expect(composed.matches.length, 1);
      expect(composed.matches.first.venue.id, '1');
      expect(composed.groupCounts.drinks, 1);
    });
  });

  group('SearchRanking', () {
    test('scores direct venue name matches highest', () {
      const match = _TestMatch(
        venue: _TestVenue(id: '1', name: 'Neon Room'),
        directVenueMatch: true,
      );

      final exact = SearchRanking.score(match, 'neon room');
      final partial = SearchRanking.score(
        const _TestMatch(
          venue: _TestVenue(id: '2', name: 'Neon Lounge'),
          directVenueMatch: true,
        ),
        'neon room',
      );

      expect(exact, greaterThan(partial));
    });
  });
}
