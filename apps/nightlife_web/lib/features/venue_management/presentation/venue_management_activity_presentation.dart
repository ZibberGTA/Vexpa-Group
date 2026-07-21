import 'package:flutter/material.dart';

/// UI-ready content for a venue management activity feed row.
class VenueManagementActivityPresentation {
  const VenueManagementActivityPresentation({
    required this.icon,
    required this.title,
    this.description,
    this.actorDisplayName,
    required this.timestampLabel,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actorDisplayName;
  final String timestampLabel;

  String get metadataLine {
    final actor = actorDisplayName?.trim();
    if (actor != null && actor.isNotEmpty) {
      return '$actor • $timestampLabel';
    }
    return timestampLabel;
  }
}
