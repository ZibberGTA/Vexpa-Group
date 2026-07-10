import 'package:flutter_test/flutter_test.dart';
import 'package:vex_engines/discovery/application/discovery_recommendation_scorer.dart';
import 'package:vex_engines/discovery/application/discovery_trending_scorer.dart';
import 'package:vex_engines/discovery/domain/discovery_recommendation.dart';
import 'package:vex_engines/discovery/domain/discovery_trending.dart';

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
  });
}
