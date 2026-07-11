import 'package:flutter_test/flutter_test.dart';
import 'package:vex_engines/discovery/application/discovery_nearby_sorter.dart';
import 'package:vex_engines/discovery/application/discovery_trending_scorer.dart';
import 'package:vex_engines/discovery/application/discovery_venue_client_matcher.dart';
import 'package:vex_engines/discovery/domain/discovery_recommendation.dart';
import 'package:vex_engines/discovery/domain/discovery_trending.dart';
import 'package:vex_engines/discovery/domain/discovery_venue_catalog_entry.dart';
import 'package:vex_engines/discovery/shared/discovery_venue_search_term_builder.dart';
import 'package:vex_engines/discovery/application/discovery_recommendation_scorer.dart';

import 'package:nightlife_app/features/venues/models/venue_filter_model.dart';
import 'package:nightlife_app/features/venues/utils/search_term_builder.dart';

void main() {
  group('Mobile discovery engine delegation', () {
    test('trending scorer matches legacy weight ordering', () {
      const scorer = DiscoveryTrendingScorer();
      final busy = scorer.score(
        const TrendingScoreInput(
          venueViews: 50,
          favouriteTaps: 20,
          crowdUpdates: 10,
          drinkViews: 15,
          dealViews: 8,
          eventViews: 4,
          crowdLevel: 'packed',
          boostScore: 25,
        ),
      );
      final quiet = scorer.score(
        const TrendingScoreInput(
          venueViews: 5,
          favouriteTaps: 1,
          crowdUpdates: 0,
          drinkViews: 0,
          dealViews: 0,
          eventViews: 0,
          crowdLevel: 'quiet',
          boostScore: 0,
        ),
      );

      expect(busy.score, greaterThan(quiet.score));
    });

    test('recommendation scorer preserves deal and event weighting', () {
      const scorer = DiscoveryRecommendationScorer();
      final scored = scorer.score(
        const RecommendationScoreInput(
          crowdLevel: 'busy',
          activeDealCount: 2,
          upcomingEventCount: 1,
          hasDealsFlag: true,
        ),
      );

      expect(scored.score, 25 + 30 + 20 + 5);
    });

    test('SearchTermBuilder delegates to DiscoveryVenueSearchTermBuilder', () {
      final shimTerms = SearchTermBuilder.build(
        venueName: 'Whisky Bar',
        category: 'Bar',
      );
      final engineTerms = DiscoveryVenueSearchTermBuilder.buildVenueIndexTerms(
        venueName: 'Whisky Bar',
        category: 'Bar',
      );

      expect(shimTerms, engineTerms);
    });

    test('VenueFilterModel hasActiveFilters uses engine filter state', () {
      const filter = VenueFilterModel(searchText: 'cocktails');
      expect(filter.hasActiveFilters, isTrue);
      expect(filter.toDiscoveryFilterState().searchText, 'cocktails');
      expect(filter.toDiscoveryFilterState().hasActiveFilters, isTrue);
    });

    test('DiscoveryVenueClientMatcher preserves mobile relevance ordering', () {
      final venues = [
        _MobileVenue(name: 'Neon Bar'),
        _MobileVenue(name: 'Neon'),
      ];

      DiscoveryVenueClientMatcher.sortByMobileRelevance(
        items: venues,
        query: 'neon',
        readName: (venue) => venue.name,
      );

      expect(venues.first.name, 'Neon');
    });

    test('DiscoveryBoostEvaluator rejects expired boosts', () {
      final now = DateTime(2026, 6, 1, 12);

      expect(
        DiscoveryBoostEvaluator.isBoostActive(
          active: true,
          endsAt: DateTime(2026, 6, 1, 11),
          now: now,
        ),
        isFalse,
      );
    });

    test('DiscoveryNearbySorter fallback score matches startup ordering', () {
      final score = DiscoveryNearbySorter.fallbackPopularityScore(
        hasDeals: true,
        crowdLevel: 'packed',
        hasBannerImage: true,
      );

      expect(score, 5 + 4 + 1);
    });

    test('catalog entry matcher returns whisky alias reasons', () {
      const entry = DiscoveryVenueCatalogEntry(
        name: 'Spirit Room',
        category: 'Bar',
        crowdLevel: 'busy',
        address: 'London',
        searchTerms: ['whiskey sour'],
      );

      final reasons = DiscoveryVenueClientMatcher.matchReasons(
        venue: entry,
        query: 'whisky',
      );

      expect(reasons, contains('whiskey sour'));
    });
  });
}

final class _MobileVenue {
  const _MobileVenue({required this.name});

  final String name;
}
