import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/constants/app_strings.dart';
import 'package:nightlife_web/core/routing/app_router.dart';

void main() {
  group('AppRouter public platform routes', () {
    test('builds entity detail paths', () {
      expect(AppRouter.venueDetails('abc'), '/venue/abc');
      expect(AppRouter.eventDetails('evt-1'), '/event/evt-1');
      expect(AppRouter.trailDetails('trail-1'), '/trail/trail-1');
    });

    test('defines all major public routes', () {
      expect(AppRouter.home, '/');
      expect(AppRouter.map, '/map');
      expect(AppRouter.search, '/search');
      expect(AppRouter.saved, '/saved');
      expect(AppRouter.account, '/account');
      expect(AppRouter.login, '/login');
      expect(AppRouter.register, '/register');
      expect(AppRouter.forgotPassword, '/forgot-password');
      expect(AppRouter.admin, '/admin');
      expect(AppRouter.venueDashboard, '/venue/dashboard');
      expect(AppRouter.deals, '/deals');
      expect(AppRouter.download, '/download');
      expect(AppRouter.business, '/business');
      expect(AppRouter.businessPricing, '/business/pricing');
      expect(AppRouter.businessClaim, '/business/claim');
    });

    test('public nav includes Home link', () {
      expect(AppStrings.publicNavLinks.first, (label: 'Home', route: '/'));
    });
  });
}
