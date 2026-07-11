/// Selects the active venue from an accessible venue list.
final class VenueActiveVenueSelector {
  const VenueActiveVenueSelector();

  String? selectVenueId({
    required List<String> accessibleVenueIds,
    required List<String> roleVenueIds,
    String? preferredVenueId,
  }) {
    if (accessibleVenueIds.isEmpty) return null;

    if (preferredVenueId != null) {
      final trimmed = preferredVenueId.trim();
      if (trimmed.isNotEmpty && accessibleVenueIds.contains(trimmed)) {
        return trimmed;
      }
    }

    for (final id in roleVenueIds) {
      if (accessibleVenueIds.contains(id)) return id;
    }

    return accessibleVenueIds.first;
  }
}
