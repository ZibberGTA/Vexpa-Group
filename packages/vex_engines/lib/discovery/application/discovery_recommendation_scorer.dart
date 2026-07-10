import '../domain/discovery_recommendation.dart';

/// Pure recommendation scoring for "best right now" style discovery.
final class DiscoveryRecommendationScorer {
  const DiscoveryRecommendationScorer();

  RecommendationScoreResult score(RecommendationScoreInput input) {
    var score = 0;
    final reasons = <String>[];

    final crowd = input.crowdLevel.toLowerCase();
    if (crowd == 'packed') {
      score += 35;
      reasons.add('packed now');
    } else if (crowd == 'busy') {
      score += 25;
      reasons.add('busy now');
    } else if (crowd == 'medium' || crowd == 'steady' || crowd == 'lively') {
      score += 12;
      reasons.add('good atmosphere');
    }

    if (input.activeDealCount > 0) {
      score += input.activeDealCount * 15;
      reasons.add(
        '${input.activeDealCount} active deal${input.activeDealCount == 1 ? '' : 's'}',
      );
    }

    if (input.upcomingEventCount > 0) {
      score += input.upcomingEventCount * 20;
      reasons.add(
        '${input.upcomingEventCount} upcoming event${input.upcomingEventCount == 1 ? '' : 's'}',
      );
    }

    if (input.hasDealsFlag) score += 5;

    return RecommendationScoreResult(
      score: score,
      reason: reasons.take(2).join(' • '),
    );
  }

  List<T> rankByScore<T>({
    required Iterable<T> items,
    required int Function(T item) readScore,
    required int Function(T a, T b) tieBreaker,
    int limit = 6,
  }) {
    final sorted = items.toList()
      ..sort((a, b) {
        final scoreDiff = readScore(b).compareTo(readScore(a));
        if (scoreDiff != 0) return scoreDiff;
        return tieBreaker(a, b);
      });
    return sorted.where((item) => readScore(item) > 0).take(limit).toList();
  }
}
