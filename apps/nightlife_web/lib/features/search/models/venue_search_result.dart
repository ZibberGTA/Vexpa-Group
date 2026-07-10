import 'package:flutter/material.dart';

import '../../venues/models/image_position_metadata.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Search result model for cards and map markers.
class VenueSearchResult {
  const VenueSearchResult({
    required this.id,
    required this.name,
    required this.area,
    required this.city,
    this.postcode = '',
    required this.venueType,
    required this.rating,
    required this.tags,
    required this.bannerGradient,
    required this.logoGradient,
    required this.resultReason,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
    this.bannerImageUrl,
    this.logoUrl,
    this.bannerImagePosition,
    this.logoImagePosition,
  });

  final String id;
  final String name;
  final String area;
  final String city;
  final String postcode;
  final String venueType;
  final double rating;
  final List<String> tags;
  final List<Color> bannerGradient;
  final List<Color> logoGradient;
  final String resultReason;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final String? bannerImageUrl;
  final String? logoUrl;
  final ImagePositionMetadata? bannerImagePosition;
  final ImagePositionMetadata? logoImagePosition;

  String get locationLabel => '$area, $city';

  LatLng get position => LatLng(latitude, longitude);
}
