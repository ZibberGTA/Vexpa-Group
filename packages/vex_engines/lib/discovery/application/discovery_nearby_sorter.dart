import '../shared/discovery_geo_utils.dart';

/// Nearby distance ordering and popularity fallback for discovery lists.
final class DiscoveryNearbySorter {
  DiscoveryNearbySorter._();

  static const _kmToMiles = 0.621371;

  static double distanceMiles({
    required double userLatitude,
    required double userLongitude,
    required double? venueLatitude,
    required double? venueLongitude,
  }) {
    if (venueLatitude == null || venueLongitude == null) {
      return double.maxFinite;
    }

    final distanceKm = DiscoveryGeoUtils.distanceKm(
      lat1: userLatitude,
      lng1: userLongitude,
      lat2: venueLatitude,
      lng2: venueLongitude,
    );

    return distanceKm * _kmToMiles;
  }

  static int fallbackPopularityScore({
    required bool hasDeals,
    required String crowdLevel,
    required bool hasBannerImage,
  }) {
    var score = 0;
    if (hasDeals) score += 5;

    final level = crowdLevel.toLowerCase();
    if (level.contains('busy')) score += 3;
    if (level.contains('packed')) score += 4;
    if (hasBannerImage) score += 1;

    return score;
  }

  static void sortByNearby<T>({
    required List<T> items,
    double? userLatitude,
    double? userLongitude,
    required double? Function(T item) readVenueLatitude,
    required double? Function(T item) readVenueLongitude,
    required int Function(T item) readFallbackScore,
  }) {
    if (userLatitude == null || userLongitude == null) {
      items.sort(
        (a, b) => readFallbackScore(b).compareTo(readFallbackScore(a)),
      );
      return;
    }

    items.sort((a, b) {
      final aDistance = distanceMiles(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        venueLatitude: readVenueLatitude(a),
        venueLongitude: readVenueLongitude(a),
      );
      final bDistance = distanceMiles(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        venueLatitude: readVenueLatitude(b),
        venueLongitude: readVenueLongitude(b),
      );
      return aDistance.compareTo(bDistance);
    });
  }
}
