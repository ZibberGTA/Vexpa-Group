import 'package:flutter/material.dart';

class VenuePreview {
  const VenuePreview({
    required this.name,
    required this.area,
    required this.rating,
    required this.tags,
    required this.imageGradient,
    this.bannerImageUrl,
    this.logoUrl,
  });

  final String name;
  final String area;
  final double rating;
  final List<String> tags;
  final List<Color> imageGradient;
  final String? bannerImageUrl;
  final String? logoUrl;
}
