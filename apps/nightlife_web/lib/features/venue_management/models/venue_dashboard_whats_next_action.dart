import 'package:flutter/material.dart';

import 'venue_dashboard_tab.dart';

/// A suggested next step shown on the venue dashboard home tab.
class VenueDashboardWhatsNextAction {
  const VenueDashboardWhatsNextAction({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.icon,
    required this.targetTab,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final IconData icon;
  final VenueDashboardTab targetTab;

  static const List<VenueDashboardWhatsNextAction> mockActions = [
    VenueDashboardWhatsNextAction(
      title: 'Add more photos',
      message: 'Venues with more photos get 2x more views.',
      buttonLabel: 'Upload photos',
      icon: Icons.photo_library_outlined,
      targetTab: VenueDashboardTab.gallery,
    ),
    VenueDashboardWhatsNextAction(
      title: 'Create a new deal',
      message: 'Deals increase customer engagement.',
      buttonLabel: 'Create deal',
      icon: Icons.local_offer_outlined,
      targetTab: VenueDashboardTab.deals,
    ),
    VenueDashboardWhatsNextAction(
      title: 'Add an upcoming event',
      message: 'Events bring more people through the door.',
      buttonLabel: 'Add event',
      icon: Icons.event_outlined,
      targetTab: VenueDashboardTab.events,
    ),
    VenueDashboardWhatsNextAction(
      title: 'Complete your profile',
      message: 'Finish the last three steps to boost visibility.',
      buttonLabel: 'Go to profile',
      icon: Icons.storefront_outlined,
      targetTab: VenueDashboardTab.venueProfile,
    ),
  ];
}
