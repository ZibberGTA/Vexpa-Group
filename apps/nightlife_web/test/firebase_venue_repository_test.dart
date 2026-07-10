import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/firebase_venue_repository.dart';
import 'package:nightlife_web/features/search/data/search_venue_repository.dart';
import 'package:nightlife_web/features/search/data/sources/venue_search_data_source.dart';
import 'package:nightlife_web/features/search/models/venue_search_result.dart';
import 'package:vex_core/vex_core.dart';

import 'support/mock_venue_repository.dart';

void main() {
  group('FirebaseVenueRepository.mapVenueData', () {
    test('maps Firestore venue documents into VexCore venues', () {
      final venues = FirebaseVenueRepository.mapVenueData([
        MapEntry('venue-1', {
          'name': 'Neon Room',
          'category': 'Cocktail Bar',
          'venueType': 'Cocktail Bar',
          'address': {
            'line1': '1 Brick Lane',
            'area': 'Shoreditch',
            'city': 'London',
            'postcode': 'E1 6PU',
          },
          'lat': 51.52,
          'lng': -0.08,
          'searchTerms': ['neon', 'room'],
          'featureTags': ['Cocktails'],
          'averageRating': 4.7,
        }),
      ]);

      expect(venues, hasLength(1));
      expect(venues.first.id, 'venue-1');
      expect(venues.first.name, 'Neon Room');
      expect(venues.first.city, 'London');
      expect(venues.first.latitude, 51.52);
      expect(venues.first.longitude, -0.08);
      expect(venues.first.searchTerms, ['neon', 'room']);
      expect(venues.first.hasValidCoordinates, isTrue);
    });
  });

  group('SearchVenueRepository via VenueDataService', () {
    test('uses mock repository data and preserves fallback for invalid coordinates',
        () async {
      final repository = SearchVenueRepository(
        venueDataService: VenueDataService(
          repository: MockVenueRepository(
            publicVenues: [
              const Venue(
                id: 'missing-coords',
                name: 'Hidden Venue',
                address: 'Unknown',
                area: 'Shoreditch',
                city: 'London',
                category: 'Bar',
                venueType: 'Bar',
                crowdLevel: 'quiet',
              ),
            ],
          ),
        ),
      );

      final catalog = await repository.loadVenues();

      expect(catalog.usingFallback, isTrue);
      expect(catalog.venues, isNotEmpty);
    });

    test('maps valid venues from VexCore catalog', () async {
      final repository = SearchVenueRepository(
        venueDataService: VenueDataService(
          repository: MockVenueRepository(
            publicVenues: [
              const Venue(
                id: 'venue-1',
                name: 'Alpha',
                address: '1 Test Street',
                area: 'Shoreditch',
                city: 'London',
                category: 'Bar',
                venueType: 'Bar',
                crowdLevel: 'quiet',
                latitude: 51.52,
                longitude: -0.08,
              ),
            ],
          ),
        ),
      );

      final catalog = await repository.loadVenues();

      expect(catalog.usingFallback, isFalse);
      expect(catalog.venues.single.name, 'Alpha');
    });
  });

  group('VenueSearchDataSource via VenueDataService', () {
    test('merges discovery index matches with in-memory catalog matches', () async {
      final dataSource = VenueSearchDataSource(
        venueDataService: VenueDataService(
          repository: MockVenueRepository(
            searchMatches: {'venue-1'},
          ),
        ),
      );

      final results = await dataSource.search(
        query: 'neon',
        catalog: [
          _venue(id: 'venue-1', name: 'Neon Room'),
          _venue(id: 'venue-2', name: 'Pulse Bar', city: 'Birmingham'),
        ],
      );

      expect(results.map((venue) => venue.id), ['venue-1']);
    });
  });
}

VenueSearchResult _venue({
  required String id,
  required String name,
  String city = 'London',
}) {
  return VenueSearchResult(
    id: id,
    name: name,
    area: 'Shoreditch',
    city: city,
    postcode: 'E1 6PU',
    venueType: 'Cocktail Bar',
    rating: 4.5,
    tags: const ['Cocktails'],
    bannerGradient: const [],
    logoGradient: const [],
    resultReason: 'Open until late',
    isOpen: true,
    latitude: 51.52,
    longitude: -0.08,
  );
}
