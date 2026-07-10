import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  group('RouteAccess', () {
    test('admin portal requires admin dashboard role', () {
      final identity = VexIdentity.fromProfile(
        uid: 'admin-1',
        dashboardRole: DashboardRole.admin,
        roleLevel: 30,
        staffFlag: true,
      );

      expect(RouteAccess.canAccessAdminPortal(identity), isTrue);
    });

    test('venue owners cannot access admin portal', () {
      final identity = VexIdentity.fromProfile(
        uid: 'owner-1',
        dashboardRole: DashboardRole.venueOwner,
      );

      expect(RouteAccess.canAccessAdminPortal(identity), isFalse);
      expect(RouteAccess.canAccessVenueDashboard(identity), isTrue);
    });

    test('regular users cannot access either dashboard', () {
      final identity = VexIdentity.fromProfile(
        uid: 'user-1',
        dashboardRole: DashboardRole.regularUser,
      );

      expect(RouteAccess.canAccessAdminPortal(identity), isFalse);
      expect(RouteAccess.canAccessVenueDashboard(identity), isFalse);
    });

    test('suspended admin is denied admin portal access', () {
      final identity = VexIdentity.fromProfile(
        uid: 'admin-suspended',
        dashboardRole: DashboardRole.admin,
        status: AccountStatus.suspended,
        roleLevel: 30,
        staffFlag: true,
      );

      expect(RouteAccess.canAccessAdminPortal(identity), isFalse);
    });

    test('disabled admin is denied admin portal access', () {
      final identity = VexIdentity.fromProfile(
        uid: 'admin-disabled',
        dashboardRole: DashboardRole.admin,
        status: AccountStatus.disabled,
        roleLevel: 30,
        staffFlag: true,
      );

      expect(RouteAccess.canAccessAdminPortal(identity), isFalse);
    });

    test('deleted admin is denied admin portal access', () {
      final identity = VexIdentity.fromProfile(
        uid: 'admin-deleted',
        dashboardRole: DashboardRole.admin,
        status: AccountStatus.deleted,
        roleLevel: 30,
        staffFlag: true,
      );

      expect(RouteAccess.canAccessAdminPortal(identity), isFalse);
    });
  });
}
