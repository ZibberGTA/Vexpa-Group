import 'package:flutter/material.dart';

/// Top-level destinations for the Vexda internal admin platform.
enum AdminDashboardPage {
  dashboard(
    label: 'Dashboard',
    section: 'Overview',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    collectionPath: null,
    subtitle: 'Platform command centre for Vexda operations.',
  ),
  venues(
    label: 'Venues',
    section: 'Platform',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront_rounded,
    collectionPath: 'venues',
    subtitle:
        'Manage claimed and unclaimed venues from the existing venue documents.',
  ),
  venueClaims(
    label: 'Venue Claims',
    section: 'Platform',
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check_rounded,
    collectionPath: 'venue_claims',
    subtitle:
        'Review ownership claims, confidence scoring, evidence and draft venue changes.',
  ),
  users(
    label: 'Users',
    section: 'Platform',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    collectionPath: 'users',
    subtitle: 'Customers, venue owners and admins from users/{uid}.',
  ),
  teamMembers(
    label: 'Team Members',
    section: 'Platform',
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings_rounded,
    collectionPath: 'staff',
    subtitle: 'Internal Vexda team roles and permissions.',
    superAdminOnly: true,
  ),
  drinks(
    label: 'Drinks',
    section: 'Content',
    icon: Icons.local_bar_outlined,
    selectedIcon: Icons.local_bar_rounded,
    collectionPath: 'drinks',
    subtitle: 'Global drink moderation using the existing drinks collection.',
  ),
  deals(
    label: 'Deals',
    section: 'Content',
    icon: Icons.local_offer_outlined,
    selectedIcon: Icons.local_offer_rounded,
    collectionPath: 'deals',
    subtitle: 'Feature, archive and moderate live venue deals.',
  ),
  events(
    label: 'Events',
    section: 'Content',
    icon: Icons.event_outlined,
    selectedIcon: Icons.event_rounded,
    collectionPath: 'events',
    subtitle: 'Publish, feature and moderate venue events.',
  ),
  trails(
    label: 'Trails',
    section: 'Content',
    icon: Icons.route_outlined,
    selectedIcon: Icons.route_rounded,
    collectionPath: 'trails',
    subtitle: 'Trail publishing, archive state, analytics and moderation.',
  ),
  trailParticipationReview(
    label: 'Trail Participation',
    section: 'Content',
    icon: Icons.how_to_reg_outlined,
    selectedIcon: Icons.how_to_reg_rounded,
    collectionPath: 'workflow_requests',
    subtitle:
        'Review venue trail participation requests, decisions and audit history.',
  ),
  reviews(
    label: 'Reviews',
    section: 'Content',
    icon: Icons.rate_review_outlined,
    selectedIcon: Icons.rate_review_rounded,
    collectionPath: null,
    subtitle:
        'Reported reviews, appeals and restoration queue. TODO: reviews are currently denormalized on venues; no reviews collection exists yet.',
  ),
  photos(
    label: 'Photos',
    section: 'Content',
    icon: Icons.photo_library_outlined,
    selectedIcon: Icons.photo_library_rounded,
    collectionPath: 'venues',
    subtitle:
        'Reported images and restore/remove actions. Venue media remains under venues/{id}/media; no media reports collection exists yet.',
  ),
  subscriptions(
    label: 'Subscriptions',
    section: 'Business',
    icon: Icons.workspace_premium_outlined,
    selectedIcon: Icons.workspace_premium_rounded,
    collectionPath: 'customers',
    subtitle: 'Stripe customer records and subscription hooks.',
  ),
  payments(
    label: 'Payments',
    section: 'Business',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments_rounded,
    collectionPath: 'payment_events',
    subtitle: 'Payment events, invoices, failures and refund workflow.',
  ),
  promotions(
    label: 'Promotions',
    section: 'Business',
    icon: Icons.campaign_outlined,
    selectedIcon: Icons.campaign_rounded,
    collectionPath: 'venue_boosts',
    subtitle: 'Featured venues, sponsored placements and campaign management.',
  ),
  platformAnalytics(
    label: 'Platform Analytics',
    section: 'Analytics',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
    collectionPath: 'analytics',
    subtitle: 'Growth, revenue, searches, registrations and monthly reporting.',
  ),
  searchIntelligence(
    label: 'Search Intelligence',
    section: 'Analytics',
    icon: Icons.manage_search_outlined,
    selectedIcon: Icons.manage_search_rounded,
    collectionPath: 'analytics',
    subtitle:
        'Most searched venues, cities, drinks and categories. TODO: define search event analytics schema.',
  ),
  venueIntelligence(
    label: 'Venue Intelligence',
    section: 'Analytics',
    icon: Icons.query_stats_outlined,
    selectedIcon: Icons.query_stats_rounded,
    collectionPath: 'analytics',
    subtitle: 'Top venues, fastest growth and engagement outliers.',
  ),
  reports(
    label: 'Reports',
    section: 'Analytics',
    icon: Icons.table_chart_outlined,
    selectedIcon: Icons.table_chart_rounded,
    collectionPath: 'reports',
    subtitle: 'CSV exports and monthly platform reports.',
  ),
  supportTickets(
    label: 'Support Tickets',
    section: 'Support',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent_rounded,
    collectionPath: 'reports',
    subtitle:
        'Support queue, assignment, replies and closure history using the existing reports queue.',
  ),
  feedback(
    label: 'Feedback',
    section: 'Support',
    icon: Icons.feedback_outlined,
    selectedIcon: Icons.feedback_rounded,
    collectionPath: 'reports',
    subtitle:
        'Bug reports, feature requests and suggestions through the existing reports surface.',
  ),
  notifications(
    label: 'Notifications',
    section: 'Support',
    icon: Icons.notifications_active_outlined,
    selectedIcon: Icons.notifications_active_rounded,
    collectionPath: 'notifications',
    subtitle: 'Broadcast, push and email announcement tooling.',
  ),
  moderation(
    label: 'Moderation',
    section: 'Security',
    icon: Icons.gpp_maybe_outlined,
    selectedIcon: Icons.gpp_maybe_rounded,
    collectionPath: 'reports',
    subtitle:
        'Reported content, fraud signals, duplicate venues and suspicious accounts.',
  ),
  auditLog(
    label: 'Audit Log',
    section: 'Security',
    icon: Icons.history_edu_outlined,
    selectedIcon: Icons.history_edu_rounded,
    collectionPath: 'audit_logs',
    subtitle: 'Important admin actions, affected documents and timestamps.',
    superAdminOnly: true,
  ),
  systemHealth(
    label: 'System Health',
    section: 'Security',
    icon: Icons.monitor_heart_outlined,
    selectedIcon: Icons.monitor_heart_rounded,
    collectionPath: null,
    subtitle: 'Firestore, Storage, Firebase, Functions and error status.',
    superAdminOnly: true,
  ),
  categories(
    label: 'Categories',
    section: 'Configuration',
    icon: Icons.category_outlined,
    selectedIcon: Icons.category_rounded,
    collectionPath: 'app_settings',
    subtitle: 'Venue, drink, feature, event and trail category configuration.',
  ),
  applicationSettings(
    label: 'Application Settings',
    section: 'Configuration',
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune_rounded,
    collectionPath: 'app_settings',
    subtitle:
        'Feature flags, maintenance mode, homepage configuration and defaults.',
  ),
  subscriptionSettings(
    label: 'Subscription Settings',
    section: 'Configuration',
    icon: Icons.price_change_outlined,
    selectedIcon: Icons.price_change_rounded,
    collectionPath: 'subscriptions',
    subtitle: 'Pricing, limits, feature access and trial periods.',
  ),
  branding(
    label: 'Branding',
    section: 'Configuration',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome_rounded,
    collectionPath: 'app_settings',
    subtitle: 'Homepage banners, marketing messages and featured campaigns.',
  ),
  developer(
    label: 'Developer',
    section: 'Developer',
    icon: Icons.developer_mode_outlined,
    selectedIcon: Icons.developer_mode_rounded,
    collectionPath: null,
    subtitle: 'Database explorer, Firebase diagnostics and debug tools.',
    superAdminOnly: true,
  ),
  adminMap(
    label: 'Admin Map',
    section: 'Map',
    icon: Icons.map_outlined,
    selectedIcon: Icons.map_rounded,
    collectionPath: 'venue_claim_directory',
    subtitle:
        'Internal onboarding coverage map from the dedicated venue_claim_directory collection only.',
  );

  const AdminDashboardPage({
    required this.label,
    required this.section,
    required this.icon,
    required this.selectedIcon,
    required this.collectionPath,
    required this.subtitle,
    this.superAdminOnly = false,
  });

  final String label;
  final String section;
  final IconData icon;
  final IconData selectedIcon;
  final String? collectionPath;
  final String subtitle;

  /// Legacy access flag for nav labelling.
  /// TODO(permission-framework): Replace with PermissionService.has(...) checks per page.
  final bool superAdminOnly;
}

class AdminDocumentRow {
  const AdminDocumentRow({
    required this.id,
    required this.path,
    required this.data,
  });

  final String id;
  final String path;
  final Map<String, dynamic> data;

  String readString(List<String> keys, {String fallback = '—'}) {
    for (final key in keys) {
      final value = data[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  bool readBool(List<String> keys) {
    for (final key in keys) {
      if (data[key] == true) return true;
    }
    return false;
  }
}
