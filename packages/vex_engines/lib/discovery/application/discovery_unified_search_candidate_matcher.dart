import 'package:vex_core/discovery/searchable_content_records.dart';
import 'package:vex_engines/experience/application/experience_drink_visibility.dart';

import '../domain/search_match_models.dart';
import '../shared/search_text_utils.dart';

/// Text and visibility checks for searchable entity rows.
final class DiscoveryUnifiedSearchCandidateMatcher {
  const DiscoveryUnifiedSearchCandidateMatcher();

  bool matchesDrink(SearchableDrinkRecord drink, String cleanQuery) {
    if (!ExperienceDrinkVisibility.isPublicVisible(
      isDeleted: drink.isDeleted,
      available: drink.available,
    )) {
      return false;
    }

    if (cleanQuery.isEmpty) return true;

    return SearchTextUtils.containsQuery(drink.name, cleanQuery) ||
        SearchTextUtils.containsQuery(drink.brand, cleanQuery) ||
        SearchTextUtils.containsQuery(drink.category, cleanQuery) ||
        SearchTextUtils.containsQuery(drink.ingredients, cleanQuery) ||
        SearchTextUtils.containsQuery(drink.searchTerms, cleanQuery) ||
        SearchTextUtils.containsQuery(drink.searchKeywords, cleanQuery);
  }

  MatchedDrink? toMatchedDrink(SearchableDrinkRecord drink) {
    if (drink.id.isEmpty || drink.venueId.isEmpty) return null;
    return MatchedDrink(
      id: drink.id,
      name: drink.name,
      category: drink.category,
      price: drink.priceLabel,
      available: drink.available,
    );
  }

  bool matchesDeal(SearchableDealRecord deal, String cleanQuery) {
    if (deal.isDeleted || !deal.isActive) return false;

    if (cleanQuery.isEmpty) return true;

    return SearchTextUtils.containsQuery(deal.title, cleanQuery) ||
        SearchTextUtils.containsQuery(deal.description, cleanQuery) ||
        SearchTextUtils.containsQuery(deal.category, cleanQuery) ||
        SearchTextUtils.containsQuery(deal.searchTerms, cleanQuery) ||
        SearchTextUtils.containsQuery(deal.searchKeywords, cleanQuery);
  }

  MatchedDeal? toMatchedDeal(SearchableDealRecord deal) {
    if (deal.id.isEmpty || deal.venueId.isEmpty) return null;
    return MatchedDeal(id: deal.id, title: deal.title);
  }

  bool matchesEvent(SearchableEventRecord event, String cleanQuery, {DateTime? now}) {
    if (event.isDeleted) return false;

    final clock = now ?? DateTime.now();
    final endDate = event.endDateTime ??
        event.startDateTime?.add(const Duration(hours: 24));
    if (endDate == null || endDate.isBefore(clock)) return false;

    if (cleanQuery.isEmpty) return true;

    return SearchTextUtils.containsQuery(event.title, cleanQuery) ||
        SearchTextUtils.containsQuery(event.description, cleanQuery) ||
        SearchTextUtils.containsQuery(event.category, cleanQuery) ||
        SearchTextUtils.containsQuery(event.searchTerms, cleanQuery) ||
        SearchTextUtils.containsQuery(event.searchKeywords, cleanQuery);
  }

  MatchedEvent? toMatchedEvent(SearchableEventRecord event) {
    if (event.id.isEmpty || event.venueId.isEmpty) return null;
    return MatchedEvent(id: event.id, title: event.title);
  }

  bool matchesTrail(SearchableTrailRecord trail, String cleanQuery, {DateTime? now}) {
    if (!trail.published) return false;

    final clock = now ?? DateTime.now();
    if (trail.availabilityEnd != null && trail.availabilityEnd!.isBefore(clock)) {
      return false;
    }

    if (cleanQuery.isEmpty) return true;

    return SearchTextUtils.containsQuery(trail.name, cleanQuery) ||
        SearchTextUtils.containsQuery(trail.description, cleanQuery) ||
        SearchTextUtils.containsQuery(trail.area, cleanQuery) ||
        SearchTextUtils.containsQuery(trail.searchTerms, cleanQuery);
  }

  MatchedTrail? toMatchedTrail(SearchableTrailRecord trail) {
    if (trail.id.isEmpty || trail.name.trim().isEmpty) return null;
    return MatchedTrail(id: trail.id, name: trail.name);
  }
}
