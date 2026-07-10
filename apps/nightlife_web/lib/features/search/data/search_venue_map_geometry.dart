import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/venue_search_result.dart';
import 'search_map_coordinates.dart';

/// Map coordinate helpers for search venues.
class SearchVenueMapGeometry {
  SearchVenueMapGeometry._();

  static LatLng initialCenterFor(List<VenueSearchResult> venues) {
    if (venues.isEmpty) return SearchMapCoordinates.londonCenter;

    var latSum = 0.0;
    var lngSum = 0.0;
    for (final venue in venues) {
      latSum += venue.latitude;
      lngSum += venue.longitude;
    }

    return LatLng(
      latSum / venues.length,
      lngSum / venues.length,
    );
  }
}
