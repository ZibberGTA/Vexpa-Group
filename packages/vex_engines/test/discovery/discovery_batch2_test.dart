import 'package:test/test.dart';
import 'package:vex_engines/discovery/application/discovery_mobile_search_rules.dart';
import 'package:vex_engines/discovery/application/discovery_recommendation_scorer.dart';
import 'package:vex_engines/discovery/application/discovery_related_venue_service.dart';
import 'package:vex_engines/discovery/application/discovery_trending_scorer.dart';
import 'package:vex_engines/discovery/domain/discovery_recommendation.dart';
import 'package:vex_engines/discovery/domain/discovery_related_venue.dart';
import 'package:vex_engines/discovery/domain/discovery_trending.dart';
import 'package:vex_engines/discovery/shared/discovery_geo_utils.dart';
import 'package:vex_engines/discovery/shared/discovery_search_term_indexer.dart';
import 'package:vex_engines/discovery/shared/search_text_utils.dart';

final class _RelatedCandidate implements DiscoveryRelatedVenueCandidate {
  const _RelatedCandidate({
    required this.id,
    required this.name,
    required this.venueType,
    required this.city,
    this.tags = const [],
    this.latitude = 51.5,
    this.longitude = -0.1,
  });

  final String name;
  @override
  final String id;
  @override
  final String venueType;
  @override
  final String city;
  @override
  final List<String> tags;
  @override
  final double latitude;
  @override
  final double longitude;
}

void main() {
  group('DiscoveryRelatedVenueService', () {
    const service = DiscoveryRelatedVenueService();

    test('ranks similar venues by category, city, and tags', () {
      const subject = DiscoveryRelatedVenueSubject(
        id: 'venue-1',
        category: 'Cocktail Bar',
        city: 'London',
        tags: ['Cocktails'],
      );

      final similar = service.rankSimilar(
        subject: subject,
        candidates: const [
          _RelatedCandidate(
            id: 'venue-2',
            name: 'Electric Bar',
            venueType: 'Cocktail Bar',
            city: 'London',
          ),
          _RelatedCandidate(
            id: 'venue-3',
            name: 'Manchester Pub',
            venueType: 'Pub',
            city: 'Manchester',
          ),
        ],
      );

      expect(similar.first.id, 'venue-2');
    });

    test('orders nearby venues by distance when coordinates exist', () {
      const subject = DiscoveryRelatedVenueSubject(
        id: 'venue-1',
        category: 'Bar',
        city: 'London',
        latitude: 51.5,
        longitude: -0.1,
      );

      final nearby = service.rankNearby(
        subject: subject,
        candidates: const [
          _RelatedCandidate(
            id: 'venue-2',
            name: 'Near',
            venueType: 'Bar',
            city: 'London',
            latitude: 51.51,
            longitude: -0.11,
          ),
          _RelatedCandidate(
            id: 'venue-3',
            name: 'Far',
            venueType: 'Bar',
            city: 'London',
            latitude: 53.0,
            longitude: -2.0,
          ),
        ],
      );

      expect(nearby.first.id, 'venue-2');
    });
  });

  group('DiscoveryTrendingScorer', () {
    const scorer = DiscoveryTrendingScorer();

    test('ranks higher-view venues above lower-view venues', () {
      final high = scorer.score(
        const TrendingScoreInput(
          venueViews: 100,
          favouriteTaps: 10,
          crowdUpdates: 5,
          drinkViews: 20,
          dealViews: 10,
          eventViews: 5,
          crowdLevel: 'busy',
          boostScore: 0,
        ),
      );
      final low = scorer.score(
        const TrendingScoreInput(
          venueViews: 2,
          favouriteTaps: 0,
          crowdUpdates: 0,
          drinkViews: 0,
          dealViews: 0,
          eventViews: 0,
          crowdLevel: 'quiet',
          boostScore: 0,
        ),
      );

      expect(high.score, greaterThan(low.score));
    });
  });

  group('DiscoveryRecommendationScorer', () {
    const scorer = DiscoveryRecommendationScorer();

    test('scores packed venues with deals highest', () {
      final packed = scorer.score(
        const RecommendationScoreInput(
          crowdLevel: 'packed',
          activeDealCount: 2,
          upcomingEventCount: 1,
        ),
      );
      final quiet = scorer.score(
        const RecommendationScoreInput(
          crowdLevel: 'quiet',
          activeDealCount: 0,
          upcomingEventCount: 0,
        ),
      );

      expect(packed.score, greaterThan(quiet.score));
      expect(packed.isEligible, isTrue);
      expect(quiet.isEligible, isFalse);
    });
  });

  group('DiscoveryMobileSearchRules', () {
    test('merges duplicate drink matches once per venue', () {
      final grouped = <String, Map<String, dynamic>>{};
      final venue = {'id': 'v1', 'name': 'Neon Room'};

      DiscoveryMobileSearchMerger.upsertMatch(
        grouped: grouped,
        venueData: venue,
        buildShell: (data) => {
          'venueId': data['id'],
          'venueName': data['name'],
          'matchedDrinks': <Map<String, dynamic>>[],
          'matchedDeals': <Map<String, dynamic>>[],
          'matchedEvents': <Map<String, dynamic>>[],
        },
        drink: {'id': 'd1', 'name': 'Martini'},
      );
      DiscoveryMobileSearchMerger.upsertMatch(
        grouped: grouped,
        venueData: venue,
        buildShell: (data) => grouped[data['id'].toString()]!,
        drink: {'id': 'd1', 'name': 'Martini'},
      );

      expect(grouped.length, 1);
      expect((grouped['v1']!['matchedDrinks'] as List).length, 1);
    });

    test('sorts grouped results by match count', () {
      final results = [
        {
          'venueName': 'Beta',
          'matchedDrinks': <Map<String, dynamic>>[
            {'id': 'd1'},
          ],
          'matchedDeals': <Map<String, dynamic>>[],
          'matchedEvents': <Map<String, dynamic>>[],
        },
        {
          'venueName': 'Alpha',
          'matchedDrinks': <Map<String, dynamic>>[
            {'id': 'd1'},
            {'id': 'd2'},
          ],
          'matchedDeals': <Map<String, dynamic>>[
            {'id': 'deal-1'},
          ],
          'matchedEvents': <Map<String, dynamic>>[],
        },
      ];

      DiscoveryMobileSearchRanking.sortByMatchCount(results);
      expect(results.first['venueName'], 'Alpha');
    });
  });

  group('DiscoverySearchTermIndexer', () {
    test('adds words and n-grams', () {
      final terms = <String>{};
      DiscoverySearchTermIndexer.addText(terms, 'Neon Room Bar');
      expect(terms, contains('neon room'));
      expect(terms, contains('neon'));
    });
  });

  group('DiscoveryGeoUtils', () {
    test('calculates non-zero distance between coordinates', () {
      final distance = DiscoveryGeoUtils.distanceKm(
        lat1: 51.5,
        lng1: -0.1,
        lat2: 53.0,
        lng2: -2.0,
      );
      expect(distance, greaterThan(0));
    });
  });

  group('SearchTextUtils mobile/web parity', () {
    test('normalises and matches queries consistently', () {
      expect(SearchTextUtils.normalise('  Whisky '), 'whisky');
      expect(
        SearchTextUtils.containsQuery(['Espresso Martini'], 'press'),
        isTrue,
      );
    });
  });
}
