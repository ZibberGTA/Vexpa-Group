import 'package:flutter/material.dart' show Offset;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/map/vexda_map_constants.dart';
import 'search_preview_data.dart';

/// Mock venue coordinates for the search map foundation.
///
/// Normalised canvas positions from [SearchPreviewData.venueMapPositions] are
/// projected around central London until real venue geodata is connected.
class SearchMapCoordinates {
  SearchMapCoordinates._();

  static const LatLng londonCenter = LatLng(51.5074, -0.1278);

  /// Matches [VexdaMapConstants.defaultZoom] on the mobile map screen.
  static const double initialZoom = VexdaMapConstants.defaultZoom;

  static const double _latSpread = 0.12;
  static const double _lngSpread = 0.16;

  static List<LatLng> get venuePositions => List.generate(
        SearchPreviewData.venueMapPositions.length,
        (index) => _fromNormalized(SearchPreviewData.venueMapPositions[index]),
      );

  static LatLng positionForVenueIndex(int index) {
    return venuePositions[index];
  }

  static LatLng _fromNormalized(Offset offset) {
    final lat = londonCenter.latitude + (0.5 - offset.dy) * _latSpread;
    final lng = londonCenter.longitude + (offset.dx - 0.5) * _lngSpread;
    return LatLng(lat, lng);
  }
}
