import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/routing/app_router.dart';
import 'package:nightlife_web/features/venue_management/models/venue_dashboard_tab.dart';

void main() {
  group('AppRouter venue dashboard routes', () {
    test('builds tab deep-link paths', () {
      expect(AppRouter.venueDashboardTabRoute(VenueDashboardTab.dashboard),
          '/venue/dashboard');
      expect(AppRouter.venueDashboardTabRoute(VenueDashboardTab.map),
          AppRouter.map);
      expect(AppRouter.venueDashboardTabRoute(VenueDashboardTab.support),
          '/venue/dashboard/support');
      expect(AppRouter.venueDashboardTabRoute(VenueDashboardTab.settings),
          '/venue/dashboard/settings');
    });
  });
}
