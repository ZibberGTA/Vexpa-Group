enum SearchFilterCategory {
  venues,
  drinks,
  events,
  deals,
  trails,
  openNow;

  String get label => switch (this) {
        SearchFilterCategory.venues => 'Venues',
        SearchFilterCategory.drinks => 'Drinks',
        SearchFilterCategory.events => 'Events',
        SearchFilterCategory.deals => 'Deals',
        SearchFilterCategory.trails => 'Trails',
        SearchFilterCategory.openNow => 'Open Now',
      };

  static const List<SearchFilterCategory> all = values;
}

/// Search filter helpers shared by the search page UI.
class SearchVenueFilter {
  SearchVenueFilter._();

  static int resolveSelection({
    required int currentIndex,
    required List<int> filteredIndices,
  }) {
    if (filteredIndices.isEmpty) return -1;
    if (filteredIndices.contains(currentIndex)) return currentIndex;
    return filteredIndices.first;
  }
}
