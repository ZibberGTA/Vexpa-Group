import 'package:flutter/material.dart';

import 'venue_dashboard_tab.dart';

/// A sidebar quick action for a venue management page.
class VenuePageQuickAction {
  const VenuePageQuickAction({
    required this.label,
    required this.icon,
    this.targetTab,
    this.actionKey,
  });

  final String label;
  final IconData icon;
  final VenueDashboardTab? targetTab;

  /// Optional action key for in-page handlers (e.g. open Add Drink modal).
  final String? actionKey;
}
