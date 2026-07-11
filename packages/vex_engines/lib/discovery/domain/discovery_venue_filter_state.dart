/// Platform-independent venue discovery filter state.
class DiscoveryVenueFilterState {
  const DiscoveryVenueFilterState({
    this.searchText = '',
    this.category,
    this.crowdLevel,
    this.dealsOnly = false,
  });

  final String searchText;
  final String? category;
  final String? crowdLevel;
  final bool dealsOnly;

  bool get hasActiveFilters =>
      searchText.trim().isNotEmpty ||
      category != null ||
      crowdLevel != null ||
      dealsOnly;
}
