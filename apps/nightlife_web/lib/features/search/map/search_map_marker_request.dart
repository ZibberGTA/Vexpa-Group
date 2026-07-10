import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Marker build input for the search map.
///
/// TODO(FIREBASE): Replace mock fields with [VenueModel] / Firestore snapshot data.
class SearchMapMarkerRequest {
  const SearchMapMarkerRequest({
    required this.venueId,
    required this.venueName,
    required this.position,
    required this.sourceIndex,
    this.logoUrl,
    this.bannerImageUrl,
    this.selected = false,
    this.glow = false,
    this.glowColor,
  });

  final String venueId;
  final String venueName;
  final LatLng position;
  final int sourceIndex;
  final String? logoUrl;
  final String? bannerImageUrl;
  final bool selected;
  final bool glow;
  final Color? glowColor;
}
