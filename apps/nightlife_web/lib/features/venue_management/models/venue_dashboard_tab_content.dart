import 'venue_dashboard_tab.dart';

/// Page copy for venue dashboard tabs (placeholder framework).
class VenueDashboardTabPageCopy {
  const VenueDashboardTabPageCopy({
    required this.title,
    required this.subtitle,
    required this.placeholderMessage,
  });

  final String title;
  final String subtitle;
  final String placeholderMessage;
}

extension VenueDashboardTabPageCopyX on VenueDashboardTab {
  VenueDashboardTabPageCopy get pageCopy {
    return switch (this) {
      VenueDashboardTab.dashboard => const VenueDashboardTabPageCopy(
        title: 'Dashboard',
        subtitle: '',
        placeholderMessage: '',
      ),
      VenueDashboardTab.map => const VenueDashboardTabPageCopy(
        title: 'Map',
        subtitle: '',
        placeholderMessage: '',
      ),
      VenueDashboardTab.venueProfile => const VenueDashboardTabPageCopy(
        title: 'Venue Profile',
        subtitle: 'Manage your public venue information.',
        placeholderMessage: 'Venue profile editor coming soon.',
      ),
      VenueDashboardTab.drinks => const VenueDashboardTabPageCopy(
        title: 'Drinks',
        subtitle: 'Manage your drinks menu and categories.',
        placeholderMessage: 'Drink management coming soon.',
      ),
      VenueDashboardTab.deals => const VenueDashboardTabPageCopy(
        title: 'Deals',
        subtitle: 'Create and manage promotional offers.',
        placeholderMessage: 'Deals management coming soon.',
      ),
      VenueDashboardTab.events => const VenueDashboardTabPageCopy(
        title: 'Events',
        subtitle: 'Create and manage upcoming events.',
        placeholderMessage: 'Events management coming soon.',
      ),
      VenueDashboardTab.gallery => const VenueDashboardTabPageCopy(
        title: 'Gallery',
        subtitle: 'Manage venue photos and media.',
        placeholderMessage: 'Gallery management coming soon.',
      ),
      VenueDashboardTab.trails => const VenueDashboardTabPageCopy(
        title: 'Trails',
        subtitle:
            'Join local trails, increase exposure and attract more customers.',
        placeholderMessage: 'Trail management coming soon.',
      ),
      VenueDashboardTab.analytics => const VenueDashboardTabPageCopy(
        title: 'Analytics',
        subtitle: 'Track performance and understand customer behaviour.',
        placeholderMessage: 'Analytics dashboard coming soon.',
      ),
      VenueDashboardTab.reviews => const VenueDashboardTabPageCopy(
        title: 'Reviews',
        subtitle: 'Monitor customer feedback and ratings.',
        placeholderMessage: 'Reviews management coming soon.',
      ),
      VenueDashboardTab.team => const VenueDashboardTabPageCopy(
        title: 'Team',
        subtitle: 'Manage staff accounts, permissions and roles.',
        placeholderMessage: 'Team management coming soon.',
      ),
      VenueDashboardTab.subscription => const VenueDashboardTabPageCopy(
        title: 'Subscription',
        subtitle: 'Manage your Vexda subscription and billing.',
        placeholderMessage: 'Subscription management coming soon.',
      ),
      VenueDashboardTab.marketing => const VenueDashboardTabPageCopy(
        title: 'Marketing',
        subtitle: 'Promote your venue and reach more customers.',
        placeholderMessage: 'Marketing tools coming soon.',
      ),
      VenueDashboardTab.support => const VenueDashboardTabPageCopy(
        title: 'Support',
        subtitle: 'Raise tickets and get help from the Vexda team.',
        placeholderMessage: 'Support centre coming soon.',
      ),
      VenueDashboardTab.settings => const VenueDashboardTabPageCopy(
        title: 'Settings',
        subtitle: 'Configure your venue preferences and account settings.',
        placeholderMessage: 'Settings coming soon.',
      ),
    };
  }

  /// URL segment for deep-linking into a dashboard tab (dashboard uses root route).
  String get routeSegment {
    return switch (this) {
      VenueDashboardTab.dashboard => '',
      VenueDashboardTab.map => 'map',
      VenueDashboardTab.venueProfile => 'profile',
      VenueDashboardTab.drinks => 'drinks',
      VenueDashboardTab.deals => 'deals',
      VenueDashboardTab.events => 'events',
      VenueDashboardTab.gallery => 'gallery',
      VenueDashboardTab.trails => 'trails',
      VenueDashboardTab.analytics => 'analytics',
      VenueDashboardTab.reviews => 'reviews',
      VenueDashboardTab.team => 'team',
      VenueDashboardTab.subscription => 'subscription',
      VenueDashboardTab.marketing => 'marketing',
      VenueDashboardTab.support => 'support',
      VenueDashboardTab.settings => 'settings',
    };
  }

  static VenueDashboardTab? fromRouteSegment(String segment) {
    final normalized = segment.trim().toLowerCase();
    if (normalized.isEmpty) return VenueDashboardTab.dashboard;

    for (final tab in VenueDashboardTab.values) {
      if (tab.routeSegment == normalized) return tab;
    }
    return null;
  }
}
