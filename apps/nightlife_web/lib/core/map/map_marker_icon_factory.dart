import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'venue_map_marker.dart';
import 'vexda_map_constants.dart';

/// Creates and caches Vexda map marker icons using the same renderer as mobile.
class MapMarkerIconFactory {
  MapMarkerIconFactory._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> descriptorFor({
    required String cacheKey,
    required String venueId,
    required String venueName,
    String? imageUrl,
    bool glow = false,
    Color? glowColor,
    int size = VexdaMapConstants.markerRenderSize,
  }) async {
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final bytes = await VenueMapMarker.create(
      venueId: venueId,
      venueName: venueName,
      imageUrl: imageUrl,
      glow: glow,
      glowColor: glowColor,
      size: size,
    );

    final descriptor = BitmapDescriptor.bytes(
      bytes,
      width: VexdaMapConstants.markerDisplaySize,
      height: VexdaMapConstants.markerDisplaySize,
      imagePixelRatio: size / VexdaMapConstants.markerDisplaySize,
    );

    _cache[cacheKey] = descriptor;
    return descriptor;
  }
}
