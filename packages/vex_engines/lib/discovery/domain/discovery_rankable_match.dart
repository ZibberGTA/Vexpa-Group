import 'discovery_venue_searchable.dart';
import 'search_match_models.dart';

/// Match payload used by discovery ranking and response composition.
abstract interface class DiscoveryRankableMatch {
  DiscoveryVenueMatchable get venue;

  bool get directVenueMatch;

  List<MatchedDrink> get matchedDrinks;

  List<MatchedDeal> get matchedDeals;

  List<MatchedEvent> get matchedEvents;

  List<MatchedTrail> get matchedTrails;

  int get rankScore;
}

extension DiscoveryRankableMatchX on DiscoveryRankableMatch {
  bool get hasDrinkMatches => matchedDrinks.isNotEmpty;

  bool get hasDealMatches => matchedDeals.isNotEmpty;

  bool get hasEventMatches => matchedEvents.isNotEmpty;

  bool get hasTrailMatches => matchedTrails.isNotEmpty;
}
