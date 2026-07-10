import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nightlife_web/features/search/data/search_repository.dart';
import 'package:nightlife_web/features/search/data/search_venue_catalog.dart';
import 'package:nightlife_web/features/search/data/search_venue_filter.dart';
import 'package:nightlife_web/features/search/data/search_venue_repository.dart';
import 'package:nightlife_web/features/search/data/venue_search_matcher.dart';
import 'package:nightlife_web/features/search/models/search_match_models.dart';
import 'package:nightlife_web/features/search/models/venue_search_result.dart';

VenueSearchResult _venue({
  required String id,
  required String name,
  String area = 'Shoreditch',
  String city = 'London',
  String postcode = 'E1 6PU',
  String venueType = 'Cocktail Bar',
  List<String> tags = const ['Cocktails'],
  bool isOpen = true,
}) {
  return VenueSearchResult(
    id: id,
    name: name,
    area: area,
    city: city,
    postcode: postcode,
    venueType: venueType,
    rating: 4.5,
    tags: tags,
    bannerGradient: const [Color(0xFF3D1054), Color(0xFFFF2D95)],
    logoGradient: const [Color(0xFF2A1538), Color(0xFFFF2D95)],
    resultReason: 'Open until late',
    isOpen: isOpen,
    latitude: 51.52,
    longitude: -0.08,
  );
}

void main() {
  group('VenueSearchMatcher', () {
    test('matches venue name case-insensitively', () {
      final venue = _venue(id: '1', name: 'The Neon Room');

      expect(VenueSearchMatcher.matches(venue, 'neon'), isTrue);
      expect(VenueSearchMatcher.matches(venue, 'NEON'), isTrue);
    });

    test('matches city, area, postcode, category and tags', () {
      final venue = _venue(
        id: '1',
        name: 'Harbour Lights',
        area: 'Albert Dock',
        city: 'Liverpool',
        postcode: 'L3 4AF',
        venueType: 'Waterfront Bar',
        tags: const ['Waterfront'],
      );

      expect(VenueSearchMatcher.matches(venue, 'liverpool'), isTrue);
      expect(VenueSearchMatcher.matches(venue, 'albert'), isTrue);
      expect(VenueSearchMatcher.matches(venue, 'l3 4af'), isTrue);
      expect(VenueSearchMatcher.matches(venue, 'waterfront bar'), isTrue);
      expect(VenueSearchMatcher.matches(venue, 'waterfront'), isTrue);
    });
  });

  group('SearchVenueMatch', () {
    test('builds drink match line with emoji', () {
      final match = SearchVenueMatch(
        catalogIndex: 0,
        venue: _venue(id: '1', name: 'Neon Room'),
        matchedDrinks: const [
          MatchedDrink(id: 'd1', name: 'Espresso Martini'),
        ],
      );

      expect(match.matchLine, contains('Matched:'));
      expect(match.matchLine, contains('🍸 Espresso Martini'));
    });

    test('builds deal match line with emoji', () {
      final match = SearchVenueMatch(
        catalogIndex: 0,
        venue: _venue(id: '1', name: 'Neon Room'),
        matchedDeals: const [
          MatchedDeal(id: 'deal-1', title: '2 Cocktails £12'),
        ],
      );

      expect(match.matchLine, contains('🔥 2 Cocktails £12'));
    });
  });

  group('SearchRepository', () {
    test('returns all venues for empty query', () async {
      final repository = SearchRepository(
        venueRepository: _FakeVenueRepository([
          _venue(id: '1', name: 'Alpha'),
          _venue(id: '2', name: 'Beta'),
        ]),
      );

      await repository.loadCatalog();
      final response = await repository.search(
        query: '',
        category: SearchFilterCategory.venues,
      );

      expect(response.catalogIndices, [0, 1]);
      expect(response.groupCounts.venues, 2);
    });

    test('filters venues by query in fallback mode', () async {
      final repository = SearchRepository(
        venueRepository: _FakeVenueRepository([
          _venue(id: '1', name: 'The Neon Room', city: 'London'),
          _venue(id: '2', name: 'Pulse Bar', city: 'Birmingham'),
        ]),
      );

      await repository.loadCatalog();
      final response = await repository.search(
        query: 'neon',
        category: SearchFilterCategory.venues,
      );

      expect(response.catalogIndices, [0]);
    });

    test('returns empty for entity filters in fallback mode', () async {
      final repository = SearchRepository(
        venueRepository: _FakeVenueRepository([
          _venue(id: '1', name: 'The Neon Room'),
        ]),
      );

      await repository.loadCatalog();
      final response = await repository.search(
        query: 'martini',
        category: SearchFilterCategory.drinks,
      );

      expect(response.matches, isEmpty);
    });

    test('filters open now venues', () async {
      final repository = SearchRepository(
        venueRepository: _FakeVenueRepository([
          _venue(id: '1', name: 'Open Venue', isOpen: true),
          _venue(id: '2', name: 'Closed Venue', isOpen: false),
        ]),
      );

      await repository.loadCatalog();
      final response = await repository.search(
        query: '',
        category: SearchFilterCategory.openNow,
      );

      expect(response.catalogIndices, [0]);
    });
  });
}

class _FakeVenueRepository extends SearchVenueRepository {
  _FakeVenueRepository(this._venues);

  final List<VenueSearchResult> _venues;

  @override
  Future<SearchVenueCatalog> loadVenues() async {
    return SearchVenueCatalog(venues: _venues, usingFallback: true);
  }
}
