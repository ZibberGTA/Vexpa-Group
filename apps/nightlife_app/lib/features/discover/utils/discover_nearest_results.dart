import '../models/discover_models.dart';

/// Pure helpers for ordering and limiting Discover quick-filter results.
class DiscoverNearestResults {
  DiscoverNearestResults._();

  static int compareByDistance(DiscoverVenueResult a, DiscoverVenueResult b) {
    return _compareDistance(a.distanceMeters, b.distanceMeters);
  }

  static int compareByDistanceThenEventThenName(
    DiscoverVenueResult a,
    DiscoverVenueResult b,
  ) {
    final distanceCompare = _compareDistance(
      a.distanceMeters,
      b.distanceMeters,
    );
    if (distanceCompare != 0) return distanceCompare;

    final aStart = a.eventStart ?? DateTime(2100);
    final bStart = b.eventStart ?? DateTime(2100);
    final timeCompare = aStart.compareTo(bStart);
    if (timeCompare != 0) return timeCompare;

    return _compareNameAndId(a, b);
  }

  static int compareByDistanceThenName(
    DiscoverVenueResult a,
    DiscoverVenueResult b,
  ) {
    final distanceCompare = _compareDistance(
      a.distanceMeters,
      b.distanceMeters,
    );
    if (distanceCompare != 0) return distanceCompare;
    return _compareNameAndId(a, b);
  }

  static List<DiscoverVenueResult> limit(
    List<DiscoverVenueResult> results, {
    int max = DiscoverFilter.discoverQuickResultLimit,
  }) {
    if (results.length <= max) return results;
    return results.take(max).toList();
  }

  static int _compareNameAndId(DiscoverVenueResult a, DiscoverVenueResult b) {
    final nameCompare = a.venueName.compareTo(b.venueName);
    if (nameCompare != 0) return nameCompare;
    return a.venueId.compareTo(b.venueId);
  }

  static int _compareDistance(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}
