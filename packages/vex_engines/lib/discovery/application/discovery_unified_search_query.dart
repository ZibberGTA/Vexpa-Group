import '../domain/search_filter_category.dart';
import '../shared/search_text_utils.dart';

/// Query normalisation and category routing for unified search.
final class DiscoveryUnifiedSearchQuery {
  const DiscoveryUnifiedSearchQuery();

  String normalise(String query) => SearchTextUtils.normalise(query);

  bool isEmptyQuery(String query) => query.trim().isEmpty;

  bool shouldReturnEmptyForShortQuery({
    required String cleanQuery,
    required SearchFilterCategory category,
  }) {
    return cleanQuery.length < 2 && category != SearchFilterCategory.venues;
  }

  bool shouldSearchVenues(SearchFilterCategory category) =>
      category == SearchFilterCategory.venues ||
      category == SearchFilterCategory.openNow;

  bool shouldSearchDrinks(SearchFilterCategory category) =>
      category == SearchFilterCategory.venues ||
      category == SearchFilterCategory.drinks;

  bool shouldSearchDeals(SearchFilterCategory category) =>
      category == SearchFilterCategory.venues ||
      category == SearchFilterCategory.deals;

  bool shouldSearchEvents(SearchFilterCategory category) =>
      category == SearchFilterCategory.venues ||
      category == SearchFilterCategory.events;

  bool shouldSearchTrails(SearchFilterCategory category) =>
      category == SearchFilterCategory.venues ||
      category == SearchFilterCategory.trails;
}
