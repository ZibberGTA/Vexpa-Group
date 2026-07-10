import 'venue_dashboard_tab.dart';

/// Grouped sidebar navigation sections for the venue management dashboard.
class VenueDashboardNavSection {
  const VenueDashboardNavSection({
    required this.label,
    required this.tabs,
  });

  final String label;
  final List<VenueDashboardTab> tabs;
}

/// Sidebar category groupings aligned with the venue portal reference design.
const venueDashboardNavSections = <VenueDashboardNavSection>[
  VenueDashboardNavSection(
    label: 'OVERVIEW',
    tabs: [
      VenueDashboardTab.dashboard,
      VenueDashboardTab.map,
    ],
  ),
  VenueDashboardNavSection(
    label: 'VENUE MANAGEMENT',
    tabs: [
      VenueDashboardTab.venueProfile,
      VenueDashboardTab.drinks,
      VenueDashboardTab.deals,
      VenueDashboardTab.events,
      VenueDashboardTab.gallery,
      VenueDashboardTab.trails,
    ],
  ),
  VenueDashboardNavSection(
    label: 'INSIGHTS',
    tabs: [
      VenueDashboardTab.analytics,
      VenueDashboardTab.reviews,
    ],
  ),
  VenueDashboardNavSection(
    label: 'TEAM & ACCESS',
    tabs: [
      VenueDashboardTab.team,
      VenueDashboardTab.subscription,
    ],
  ),
  VenueDashboardNavSection(
    label: 'MARKETING',
    tabs: [VenueDashboardTab.marketing],
  ),
  VenueDashboardNavSection(
    label: 'SETTINGS',
    tabs: [
      VenueDashboardTab.settings,
      VenueDashboardTab.support,
    ],
  ),
];
