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

  static const List<VenueDashboardActivity> mockRecent = [
    VenueDashboardActivity(
      title: 'Venue profile updated',
      timestampLabel: '2 hours ago',
      icon: Icons.storefront_outlined,
    ),
    VenueDashboardActivity(
      title: 'New drink added: Espresso Martini',
      timestampLabel: '5 hours ago',
      icon: Icons.local_bar_outlined,
    ),
    VenueDashboardActivity(
      title: 'Deal created: 2-for-1 Cocktails',
      timestampLabel: 'Yesterday',
      icon: Icons.local_offer_outlined,
    ),
    VenueDashboardActivity(
      title: 'Event added: Friday DJ Night',
      timestampLabel: '2 days ago',
      icon: Icons.event_outlined,
    ),
    VenueDashboardActivity(
      title: 'Gallery photo uploaded',
      timestampLabel: '3 days ago',
      icon: Icons.photo_library_outlined,
    ),
  ];
}
