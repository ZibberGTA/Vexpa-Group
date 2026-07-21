class AppStrings {
  AppStrings._();

  static const String appName = 'Vexda';

  static const List<({String label, String route})> publicNavLinks = [
    (label: 'Home', route: '/'),
    (label: 'Map', route: '/map'),
    (label: 'Search', route: '/search'),
    (label: 'Saved', route: '/saved'),
    (label: 'Account', route: '/account'),
  ];

  // Homepage hero (WEB-HOME-EPIC-002)
  static const String heroHeadlineLine1 = 'Your night out.';
  static const String heroHeadlineLine2 = 'Perfected.';
  static const String heroSubheading =
      'Vexda helps you discover the best venues, drinks, events and experiences — '
      'all in one place. Less searching. More living.';
  static const String searchPlaceholder =
      'Search venues, drinks, events or locations...';

  static const List<String> homeHeroPhrases = [
    'Where are you heading tonight?',
    'Find your next favourite venue.',
    'Cocktails. Live music. Hidden gems.',
    'Your perfect night starts here.',
  ];

  static const String heroFeatureCardTitle =
      'The smarter way to discover nightlife.';
  static const List<String> heroFeatureCardItems = [
    'Real-time info',
    'Curated venues',
    'Exclusive deals',
    'Live events',
    'Built for your night',
  ];

  static const String downloadApp = 'Download App';
  static const String heroDownloadLink = 'Download the app →';
  static const String heroViewVenues = 'View Venues';
  static const String login = 'Login';
  static const String createAccount = 'Create Account';
  static const String logout = 'Log out';

  static const String loginTitle = 'Sign in to Vexda';
  static const String loginSubtitle =
      'Use the same email and password as the Vexda mobile app. Public browsing does not require an account.';
  static const String registerTitle = 'Create your Vexda account';
  static const String registerSubtitle =
      'Sign up as a venue owner to claim or create a venue, or as a customer to discover nightlife.';
  static const String forgotPasswordTitle = 'Reset your password';
  static const String forgotPasswordSubtitle =
      'Enter the email on your account and we will send a link to choose a new password.';
  static const String staffAccessDenied =
      'This account does not have access to the venue/admin dashboard.';
  static const String adminDashboardTitle = 'Admin dashboard';
  static const String venueDashboardTitle = 'Venue management';
  static const String venueManagementDashboardTitle =
      'Venue Management Dashboard';
  static const String venueManagementDashboardSubtitle =
      'Manage your venue profile, drinks, deals, events, team, analytics and marketing from one place.';
  static const String venueDashboardSearchPlaceholder =
      'Search your venue, drinks, deals, events, team...';
  static const String viewPublicProfile = 'View Public Profile';

  static const String venueDashboardQuickActionsTitle = 'Quick Actions';
  static const String venueDashboardActionEditProfile = 'Edit Venue Profile';
  static const String venueDashboardActionAddDrink = 'Add New Drink';
  static const String venueDashboardActionCreateDeal = 'Create a Deal';
  static const String venueDashboardActionAddEvent = 'Add Event';
  static const String venueDashboardActionUploadPhotos = 'Upload Photos';
  static const String venueDashboardRecentActivityTitle = 'Recent Activity';
  static const String venueDashboardRecentActivityEmptyTitle =
      'No recent activity';
  static const String venueDashboardRecentActivityEmptyBody =
      'Changes made to your venue will appear here.';
  static const String venueDashboardRecentActivityError =
      'Recent activity could not be loaded right now.';
  static const String venueDashboardGoPremiumTitle = 'Go Premium';
  static const String venueDashboardGoPremiumBody =
      'Unlock smarter insights, stronger promotion tools and more ways to grow your venue.';
  static const String venueDashboardGoPremiumTagline =
      'Your venue deserves more than a chalkboard outside.';
  static const String venueDashboardUpgradePlan = 'Upgrade Your Plan';
  static const String venueDashboardWelcomeSubtitle =
      'Here\'s what\'s happening with your venue today.';
  static const String venueDashboardProfileViewsTitle =
      'Profile Views Over Time';
  static const String venueDashboardProfileCompletionTitle =
      'Profile Completion';
  static const String venueDashboardImproveProfile = 'Improve Profile';
  static const String venueDashboardPerformanceHighlightsTitle =
      'Performance Highlights';
  static const String venueDashboardNextSevenDaysTitle = 'Next 7 Days';
  static const String venueDashboardNextSevenDaysSubtitle =
      'Everything happening at your venue this week';
  static const String venueDashboardViewFullCalendar = 'View Full Calendar';
  static const String venueDashboardWhatsNextTitle = 'What\'s Next?';
  static const String venueDashboardWhatsNextSubtitle =
      'Keep your profile fresh and engaging.';

  static const String whyVexdaTitle = 'Why Vexda?';

  static const String homeDownloadTitle = 'Your night. In your pocket.';
  static const String homeDownloadSubtitle = 'Take Vexda everywhere you go.';

  // Legacy / other pages
  static const String exploreVenues = 'Explore Venues';
  static const String searchPageTitle = 'Where should you go tonight?';
  static const String searchPageSubtitle =
      'Search venues, drinks, deals, events and trails across the UK.';
  static const String savedTitle = 'Saved';
  static const String savedSubtitle =
      'Your saved venues, trails and events — synced when you sign in on the app.';
  static const String accountTitle = 'Your Vexda account';
  static const String accountSubtitle =
      'Save venues, get notifications, join trails and personalise your nights out.';
  static const String dealsTitle = 'Tonight\'s best deals';
  static const String dealsSubtitle =
      'Browse active offers across venues, drinks and cities.';
  static const String businessTitle = 'Grow your venue with Vexda';
  static const String businessSubtitle =
      'Venue Experience Discovery Advertising — reach more customers and increase discoverability.';
  static const String pricingTitle = 'Plans that grow with your venue';
  static const String pricingSubtitle =
      'Choose the subscription that fits your venue. Launch pricing includes 50% off for your first 12 months.';
  static const String claimTitle = 'Claim your venue on Vexda';
  static const String claimSubtitle =
      'Verify ownership, connect your profile and start reaching customers tonight.';
  static const String downloadTitle = 'Take Vexda with you';
  static const String downloadSubtitle =
      'Save venues, join trails, get notifications and plan your night on mobile.';

  // Homepage footer
  static const String homeFooterTagline =
      'Discover more. Experience more. Live more.';
  static const String homeFooterCopyright =
      '© 2025 Vexda Ltd. All rights reserved.';

  // Shared footer fallback
  static const String footerTagline = homeFooterTagline;
  static const String footerCopyright = homeFooterCopyright;

  static const List<({String label, String route})> footerPrimaryLinks = [
    (label: 'About', route: '/'),
    (label: 'Business', route: '/business'),
    (label: 'Support', route: '/account'),
    (label: 'Privacy', route: '/'),
    (label: 'Terms', route: '/'),
    (label: 'Download App', route: '/download'),
  ];
}
