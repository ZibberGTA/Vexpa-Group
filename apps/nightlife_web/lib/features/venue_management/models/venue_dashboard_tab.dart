import 'package:flutter/material.dart';

/// Sidebar destinations for the venue management dashboard.
enum VenueDashboardTab {
  dashboard(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  map(
    label: 'Map',
    icon: Icons.map_outlined,
    selectedIcon: Icons.map_rounded,
  ),
  venueProfile(
    label: 'Venue Profile',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront_rounded,
  ),
  drinks(
    label: 'Drinks',
    icon: Icons.local_bar_outlined,
    selectedIcon: Icons.local_bar_rounded,
  ),
  deals(
    label: 'Deals',
    icon: Icons.local_offer_outlined,
    selectedIcon: Icons.local_offer_rounded,
  ),
  events(
    label: 'Events',
    icon: Icons.event_outlined,
    selectedIcon: Icons.event_rounded,
  ),
  gallery(
    label: 'Gallery',
    icon: Icons.photo_library_outlined,
    selectedIcon: Icons.photo_library_rounded,
  ),
  trails(
    label: 'Trails',
    icon: Icons.route_outlined,
    selectedIcon: Icons.route_rounded,
  ),
  analytics(
    label: 'Analytics',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
  reviews(
    label: 'Reviews',
    icon: Icons.rate_review_outlined,
    selectedIcon: Icons.rate_review_rounded,
  ),
  team(
    label: 'Team',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
  ),
  subscription(
    label: 'Subscription',
    icon: Icons.workspace_premium_outlined,
    selectedIcon: Icons.workspace_premium_rounded,
  ),
  marketing(
    label: 'Marketing',
    icon: Icons.campaign_outlined,
    selectedIcon: Icons.campaign_rounded,
  ),
  support(
    label: 'Support',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent_rounded,
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  );

  const VenueDashboardTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

extension VenueDashboardTabNavigationX on VenueDashboardTab {
  /// Map opens the public customer map — not an in-shell dashboard page.
  bool get opensPublicMap => this == VenueDashboardTab.map;
}
