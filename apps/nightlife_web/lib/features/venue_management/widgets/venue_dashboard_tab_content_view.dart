import 'package:flutter/material.dart';

import '../models/venue_dashboard_tab.dart';
import 'drinks/venue_drinks_management_page.dart';
import 'deals/venue_deals_management_page.dart';
import 'events/venue_events_management_page.dart';
import 'gallery/venue_gallery_management_page.dart';
import 'page/venue_dashboard_page_scaffold.dart';
import 'profile/venue_profile_management_page.dart';
import 'support/venue_support_management_page.dart';
import 'venue_dashboard_home_panel.dart';

/// Resolves the main content widget for each venue dashboard tab.
class VenueDashboardTabContentView extends StatelessWidget {
  const VenueDashboardTabContentView({
    super.key,
    required this.tab,
  });

  final VenueDashboardTab tab;

  static Widget forTab(VenueDashboardTab tab) {
    if (tab == VenueDashboardTab.dashboard || tab.opensPublicMap) {
      return const VenueDashboardHomePanel();
    }

    if (tab == VenueDashboardTab.drinks) {
      return const VenueDrinksManagementPage();
    }

    if (tab == VenueDashboardTab.deals) {
      return const VenueDealsManagementPage();
    }

    if (tab == VenueDashboardTab.events) {
      return const VenueEventsManagementPage();
    }

    if (tab == VenueDashboardTab.support) {
      return const VenueSupportManagementPage();
    }

    if (tab == VenueDashboardTab.venueProfile) {
      return const VenueProfileManagementPage();
    }

    if (tab == VenueDashboardTab.gallery) {
      return const VenueGalleryManagementPage();
    }

    return VenueManagementTabPage(tab: tab);
  }

  @override
  Widget build(BuildContext context) {
    return forTab(tab);
  }
}
