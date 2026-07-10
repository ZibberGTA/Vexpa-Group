import 'package:flutter/material.dart';

import '../../features/account/screens/account_page.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/widgets/auth_guard.dart';
import '../../features/business/screens/business_landing_page.dart';
import '../../features/business/screens/claim_venue_page.dart';
import '../../features/business/screens/pricing_page.dart';
import '../../features/deals/screens/deals_page.dart';
import '../../features/download/screens/download_page.dart';
import '../../features/event/screens/event_details_page.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/saved/screens/saved_page.dart';
import '../../features/search/screens/search_experience_page.dart';
import '../../features/search/screens/search_page.dart';
import '../../features/trail/screens/trail_details_page.dart';
import '../../features/venue/screens/venue_details_page.dart';
import '../../features/venue_management/models/venue_dashboard_tab.dart';
import '../../features/venue_management/models/venue_dashboard_tab_content.dart';
import '../../features/venue_management/screens/venue_dashboard_screen.dart';

class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String map = '/map';
  static const String search = '/search';
  static const String saved = '/saved';
  static const String account = '/account';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String admin = '/admin';
  static const String venueDashboard = '/venue/dashboard';
  static const String deals = '/deals';
  static const String download = '/download';
  static const String business = '/business';
  static const String businessPricing = '/business/pricing';
  static const String businessClaim = '/business/claim';
  static const String venuePrefix = '/venue/';
  static const String eventPrefix = '/event/';
  static const String trailPrefix = '/trail/';

  static String venueDetails(String venueId) => '$venuePrefix$venueId';
  static String eventDetails(String eventId) => '$eventPrefix$eventId';
  static String trailDetails(String trailId) => '$trailPrefix$trailId';

  /// Deep-link path for a venue dashboard tab within the management shell.
  static String venueDashboardTabRoute(VenueDashboardTab tab) {
    if (tab == VenueDashboardTab.dashboard) return venueDashboard;
    if (tab == VenueDashboardTab.map) return map;
    return '$venueDashboard/${tab.routeSegment}';
  }

  static VenueDashboardTab? _parseDashboardTabFromPath(String path) {
    if (path == 'dashboard') return VenueDashboardTab.dashboard;
    if (!path.startsWith('dashboard/')) return null;

    final segment = path.substring('dashboard/'.length);
    return VenueDashboardTabPageCopyX.fromRouteSegment(segment);
  }

  static MaterialPageRoute<void> _venueDashboardRoute(
    RouteSettings settings,
    VenueDashboardTab initialTab,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => AuthGuard(
        requirement: AuthGuardRequirement.venueStaff,
        child: VenueDashboardScreen(initialTab: initialTab),
      ),
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? home;

    if (name.startsWith(venuePrefix)) {
      final remainder = name.substring(venuePrefix.length).trim();
      if (remainder == 'dashboard' || remainder.startsWith('dashboard/')) {
        final tab =
            _parseDashboardTabFromPath(remainder) ??
            VenueDashboardTab.dashboard;
        if (tab == VenueDashboardTab.map) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SearchPage(),
          );
        }
        return _venueDashboardRoute(settings, tab);
      }
      if (remainder.isNotEmpty) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => VenueDetailsPage(venueId: remainder),
        );
      }
    }

    if (name.startsWith(eventPrefix)) {
      final eventId = name.substring(eventPrefix.length).trim();
      if (eventId.isNotEmpty) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => EventDetailsPage(eventId: eventId),
        );
      }
    }

    if (name.startsWith(trailPrefix)) {
      final trailId = name.substring(trailPrefix.length).trim();
      if (trailId.isNotEmpty) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => TrailDetailsPage(trailId: trailId),
        );
      }
    }

    switch (name) {
      case map:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SearchPage(),
        );
      case search:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SearchExperiencePage(),
        );
      case saved:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SavedPage(),
        );
      case account:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AccountPage(),
        );
      case login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case register:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );
      case forgotPassword:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ForgotPasswordScreen(),
        );
      case admin:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AuthGuard(
            requirement: AuthGuardRequirement.admin,
            child: AdminDashboardScreen(),
          ),
        );
      case venueDashboard:
        return _venueDashboardRoute(settings, VenueDashboardTab.dashboard);
      case deals:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const DealsPage(),
        );
      case download:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const DownloadPage(),
        );
      case business:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const BusinessLandingPage(),
        );
      case businessPricing:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const PricingPage(),
        );
      case businessClaim:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ClaimVenuePage(),
        );
      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
    }
  }
}
