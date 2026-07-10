class VenueFilterModel {
  final String searchText;
  final String? category;
  final String? crowdLevel;
  final bool dealsOnly;

  const VenueFilterModel({
    this.searchText = '',
    this.category,
    this.crowdLevel,
    this.dealsOnly = false,
  });

  VenueFilterModel copyWith({
    String? searchText,
    String? category,
    String? crowdLevel,
    bool? dealsOnly,
    bool clearCategory = false,
    bool clearCrowdLevel = false,
  }) {
    return VenueFilterModel(
      searchText: searchText ?? this.searchText,
      category: clearCategory ? null : (category ?? this.category),
      crowdLevel: clearCrowdLevel ? null : (crowdLevel ?? this.crowdLevel),
      dealsOnly: dealsOnly ?? this.dealsOnly,
    );
  }

  bool get hasActiveFilters =>
      searchText.trim().isNotEmpty ||
      category != null ||
      crowdLevel != null ||
      dealsOnly;
}