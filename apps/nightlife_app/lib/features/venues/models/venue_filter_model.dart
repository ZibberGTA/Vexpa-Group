import 'package:vex_engines/discovery/domain/discovery_venue_filter_state.dart';

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

  bool get hasActiveFilters => toDiscoveryFilterState().hasActiveFilters;

  DiscoveryVenueFilterState toDiscoveryFilterState() {
    return DiscoveryVenueFilterState(
      searchText: searchText,
      category: category,
      crowdLevel: crowdLevel,
      dealsOnly: dealsOnly,
    );
  }
}