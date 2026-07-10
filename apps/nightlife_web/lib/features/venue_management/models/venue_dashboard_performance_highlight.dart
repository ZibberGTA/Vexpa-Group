import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/venue_dashboard_tab.dart';

/// Accent palette for performance highlight card polish.
enum VenueDashboardHighlightAccent {
  purple(AppColors.primaryPurple),
  pink(AppColors.primaryPink),
  gold(AppColors.trailGold),
  emerald(Color(0xFF34D399)),
  blue(Color(0xFF60A5FA));

  const VenueDashboardHighlightAccent(this.color);

  final Color color;
}

/// A single performance insight shown on the venue dashboard home tab.
class VenueDashboardPerformanceHighlight {
  const VenueDashboardPerformanceHighlight({
    required this.message,
    required this.buttonLabel,
    required this.icon,
    this.targetTab,
    this.accent = VenueDashboardHighlightAccent.purple,
  });

  final String message;
  final String buttonLabel;
  final IconData icon;
  final VenueDashboardHighlightAccent accent;

  /// When set, the CTA switches to this dashboard tab.
  final VenueDashboardTab? targetTab;

  static const List<VenueDashboardPerformanceHighlight> mockHighlights = [
    VenueDashboardPerformanceHighlight(
      message: 'Your profile views are 18.6% higher than last week.',
      buttonLabel: 'View Analytics',
      icon: Icons.visibility_outlined,
      targetTab: VenueDashboardTab.analytics,
      accent: VenueDashboardHighlightAccent.blue,
    ),
    VenueDashboardPerformanceHighlight(
      message: 'You\'re getting more saves, 21% increase this week.',
      buttonLabel: 'View Saves',
      icon: Icons.bookmark_outline_rounded,
      targetTab: VenueDashboardTab.analytics,
      accent: VenueDashboardHighlightAccent.pink,
    ),
    VenueDashboardPerformanceHighlight(
      message: 'Your deals are performing well this week, 11% increase.',
      buttonLabel: 'Manage Deals',
      icon: Icons.local_offer_outlined,
      targetTab: VenueDashboardTab.deals,
      accent: VenueDashboardHighlightAccent.gold,
    ),
    VenueDashboardPerformanceHighlight(
      message: 'Add more photos. Venues with 10+ photos get 2x more views.',
      buttonLabel: 'Add Photos',
      icon: Icons.photo_library_outlined,
      targetTab: VenueDashboardTab.gallery,
      accent: VenueDashboardHighlightAccent.emerald,
    ),
  ];
}
