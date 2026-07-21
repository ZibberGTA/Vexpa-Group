import 'venue_dashboard_tab.dart';
import 'venue_management_activity_types.dart';

/// Maps venue dashboard tabs to canonical activity source areas.
extension VenueDashboardTabActivity on VenueDashboardTab {
  /// Returns the canonical [VenueManagementActivitySourceAreas] value for entity
  /// management pages, or null when the tab has no scoped activity feed.
  String? get activitySourceArea {
    return switch (this) {
      VenueDashboardTab.venueProfile =>
        VenueManagementActivitySourceAreas.venueProfile,
      VenueDashboardTab.drinks => VenueManagementActivitySourceAreas.drinks,
      VenueDashboardTab.deals => VenueManagementActivitySourceAreas.deals,
      VenueDashboardTab.events => VenueManagementActivitySourceAreas.events,
      VenueDashboardTab.gallery => VenueManagementActivitySourceAreas.gallery,
      _ => null,
    };
  }
}
