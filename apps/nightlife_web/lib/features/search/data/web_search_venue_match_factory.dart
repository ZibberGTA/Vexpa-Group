import 'package:vex_engines/discovery/application/discovery_unified_search_merger.dart';
import 'package:vex_engines/discovery/domain/discovery_venue_searchable.dart';
import 'package:vex_engines/discovery/domain/search_match_models.dart';

import '../models/search_match_models.dart';
import '../models/venue_search_result.dart';

/// Maps [SearchVenueMatch] instances for Discovery Engine orchestration.
final class WebSearchVenueMatchFactory
    implements DiscoveryUnifiedSearchMatchFactory<SearchVenueMatch> {
  const WebSearchVenueMatchFactory();

  @override
  SearchVenueMatch buildBase({
    required int catalogIndex,
    required DiscoveryVenueMatchable venue,
    bool directVenueMatch = false,
  }) {
    return SearchVenueMatch(
      catalogIndex: catalogIndex,
      venue: venue as VenueSearchResult,
      directVenueMatch: directVenueMatch,
    );
  }

  @override
  SearchVenueMatch merge(
    SearchVenueMatch existing, {
    bool directVenueMatch = false,
    MatchedDrink? drink,
    MatchedDeal? deal,
    MatchedEvent? event,
    MatchedTrail? trail,
  }) {
    var drinks = List<MatchedDrink>.from(existing.matchedDrinks);
    var deals = List<MatchedDeal>.from(existing.matchedDeals);
    var events = List<MatchedEvent>.from(existing.matchedEvents);
    var trails = List<MatchedTrail>.from(existing.matchedTrails);

    if (drink != null && !drinks.any((item) => item.id == drink.id)) {
      drinks.add(drink);
    }
    if (deal != null && !deals.any((item) => item.id == deal.id)) {
      deals.add(deal);
    }
    if (event != null && !events.any((item) => item.id == event.id)) {
      events.add(event);
    }
    if (trail != null && !trails.any((item) => item.id == trail.id)) {
      trails.add(trail);
    }

    return existing.copyWith(
      directVenueMatch: directVenueMatch || existing.directVenueMatch,
      matchedDrinks: drinks,
      matchedDeals: deals,
      matchedEvents: events,
      matchedTrails: trails,
    );
  }
}
