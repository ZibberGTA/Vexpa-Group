import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vex_engines/discovery/shared/discovery_map_geometry.dart';

import '../models/venue_search_result.dart';
import 'search_map_coordinates.dart';

/// Map coordinate helpers for search venues.
class SearchVenueMapGeometry {
  SearchVenueMapGeometry._();

  static LatLng initialCenterFor(List<VenueSearchResult> venues) {
    if (venues.isEmpty) return SearchMapCoordinates.londonCenter;

    final centroid = DiscoveryMapGeometry.centroid(
      venues.map(
        (venue) => DiscoveryCoordinate(
          latitude: venue.latitude,
          longitude: venue.longitude,
        ),
      ),
    );

    if (centroid == null) return SearchMapCoordinates.londonCenter;

    return LatLng(centroid.latitude, centroid.longitude);
  }
}
