import 'package:flutter/material.dart';

class TrailPreview {
  const TrailPreview({
    required this.name,
    required this.area,
    required this.stops,
    required this.duration,
    required this.tags,
    required this.imageGradient,
  });

  final String name;
  final String area;
  final int stops;
  final String duration;
  final List<String> tags;
  final List<Color> imageGradient;
}
