import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vex_engines/discovery/shared/discovery_map_geometry.dart';

import '../../home/models/venue_model.dart';
import '../../startup/models/startup_data.dart';

/// Resolves the Discover map bootstrap camera target.
///
/// Priority:
/// 1. Cached startup/device location
/// 2. Geographic centroid of venues with coordinates
/// 3. [applicationFallbackCenter] (UK centroid — last resort only)
class MapBootstrapLocation {
  MapBootstrapLocation._();

  /// UK geographic centroid used only when device location and venue geometry
  /// are unavailable. Not used as a normal launch city default.
  static const LatLng applicationFallbackCenter = LatLng(54.7023, -3.2760);

  static LatLng resolveInitialCenter({StartupData? startupData}) {
    if (startupData?.hasUserLocation == true) {
      return LatLng(
        startupData!.userLatitude!,
        startupData.userLongitude!,
      );
    }

    final venueSample = startupData != null &&
            startupData.nearbyVenues.isNotEmpty
        ? startupData.nearbyVenues
        : (startupData?.venues ?? const <VenueModel>[]);

    final centroid = centroidFromVenues(venueSample);
    if (centroid != null) return centroid;

    return applicationFallbackCenter;
  }

  static LatLng? centroidFromVenues(Iterable<VenueModel> venues) {
    final coordinates = venues
        .where((venue) => venue.location != null)
        .map(
          (venue) => DiscoveryCoordinate(
            latitude: venue.location!.latitude,
            longitude: venue.location!.longitude,
          ),
        );

    final centroid = DiscoveryMapGeometry.centroid(coordinates);
    if (centroid == null) return null;

    return LatLng(centroid.latitude, centroid.longitude);
  }
}
