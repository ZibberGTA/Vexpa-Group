import '../domain/discovery_rankable_match.dart';
import '../shared/search_text_utils.dart';

/// Ranking rules for unified discovery search — aligned with mobile priorities.
class SearchRanking {
  SearchRanking._();

  static int score(DiscoveryRankableMatch match, String query) {
    final normalized = SearchTextUtils.normalise(query);
    if (normalized.isEmpty) return 0;

    var score = 0;

    final venueName = SearchTextUtils.normalise(match.venue.name);
    if (match.directVenueMatch) {
      if (venueName == normalized) {
        score += 10000;
      } else if (venueName.startsWith(normalized)) {
        score += 5000;
      } else if (venueName.contains(normalized)) {
        score += 2000;
      } else {
        score += 500;
      }
    }

    for (final drink in match.matchedDrinks) {
      final name = SearchTextUtils.normalise(drink.name);
      if (name == normalized) {
        score += 8000;
      } else if (name.startsWith(normalized)) {
        score += 4000;
      } else if (name.contains(normalized)) {
        score += 1000;
      }
    }

    for (final deal in match.matchedDeals) {
      final title = SearchTextUtils.normalise(deal.title);
      if (title == normalized) {
        score += 7000;
      } else if (title.startsWith(normalized)) {
        score += 3500;
      } else if (title.contains(normalized)) {
        score += 900;
      }
    }

    for (final event in match.matchedEvents) {
      final title = SearchTextUtils.normalise(event.title);
      if (title == normalized) {
        score += 6000;
      } else if (title.startsWith(normalized)) {
        score += 3000;
      } else if (title.contains(normalized)) {
        score += 800;
      }
    }

    for (final trail in match.matchedTrails) {
      final name = SearchTextUtils.normalise(trail.name);
      if (name == normalized) {
        score += 5000;
      } else if (name.startsWith(normalized)) {
        score += 2500;
      } else if (name.contains(normalized)) {
        score += 700;
      }
    }

    score +=
        (match.matchedDrinks.length +
            match.matchedDeals.length +
            match.matchedEvents.length +
            match.matchedTrails.length) *
        10;

    return score;
  }

  static void sortMatches<T extends DiscoveryRankableMatch>(
    List<T> matches,
    String query,
  ) {
    matches.sort((a, b) {
      final scoreDiff = b.rankScore.compareTo(a.rankScore);
      if (scoreDiff != 0) return scoreDiff;
      return a.venue.name.toLowerCase().compareTo(b.venue.name.toLowerCase());
    });
  }
}
