import 'package:flutter/material.dart';

class EventPreview {
  const EventPreview({
    required this.name,
    required this.venue,
    required this.area,
    required this.time,
    required this.tags,
    required this.imageGradient,
  });

  final String name;
  final String venue;
  final String area;
  final String time;
  final List<String> tags;
  final List<Color> imageGradient;
}
