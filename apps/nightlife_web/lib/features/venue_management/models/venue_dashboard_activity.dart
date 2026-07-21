import 'package:flutter/material.dart';

/// A single recent-activity row for the venue dashboard sidebar.
class VenueDashboardActivity {
  const VenueDashboardActivity({
    required this.title,
    required this.timestampLabel,
    required this.icon,
  });

  final String title;
  final String timestampLabel;
  final IconData icon;
}
