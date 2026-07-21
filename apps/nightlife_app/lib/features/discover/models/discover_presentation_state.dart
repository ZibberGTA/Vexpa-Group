import 'discover_models.dart';

/// Single source of truth for transient Discover UI presentation.
class DiscoverPresentationState {
  const DiscoverPresentationState({
    this.selectedFilter,
    this.loadState = const DiscoverLoadState(),
    this.panelExpanded = true,
    this.panelShown = true,
    this.selectedVenueId,
    this.venuePreviewOpen = false,
  });

  final DiscoverFilter? selectedFilter;
  final DiscoverLoadState loadState;
  final bool panelExpanded;
  final bool panelShown;
  final String? selectedVenueId;
  final bool venuePreviewOpen;

  bool get hasActiveFilter => selectedFilter != null;

  bool get resultsPanelVisible =>
      hasActiveFilter && panelShown && !venuePreviewOpen;

  bool get shouldHideMapControls =>
      (hasActiveFilter && !venuePreviewOpen) || venuePreviewOpen;

  bool get hasSelectedVenueInResults {
    final venueId = selectedVenueId;
    if (venueId == null) return false;
    return loadState.results.any((result) => result.venueId == venueId);
  }

  DiscoverPresentationState copyWith({
    DiscoverFilter? selectedFilter,
    bool clearSelectedFilter = false,
    DiscoverLoadState? loadState,
    bool? panelExpanded,
    bool? panelShown,
    String? selectedVenueId,
    bool clearSelectedVenueId = false,
    bool? venuePreviewOpen,
  }) {
    return DiscoverPresentationState(
      selectedFilter: clearSelectedFilter
          ? null
          : (selectedFilter ?? this.selectedFilter),
      loadState: loadState ?? this.loadState,
      panelExpanded: panelExpanded ?? this.panelExpanded,
      panelShown: panelShown ?? this.panelShown,
      selectedVenueId: clearSelectedVenueId
          ? null
          : (selectedVenueId ?? this.selectedVenueId),
      venuePreviewOpen: venuePreviewOpen ?? this.venuePreviewOpen,
    );
  }

  DiscoverPresentationState cleared() => const DiscoverPresentationState();
}
