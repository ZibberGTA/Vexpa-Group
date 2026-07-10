import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  group('AdminPermissionMatrix.permissionsForRole', () {
    test('founder receives every permission', () {
      final permissions =
          AdminPermissionMatrix.permissionsForRole(StaffRole.founder);

      expect(permissions.length, StaffPermission.values.length);
      for (final permission in StaffPermission.values) {
        expect(permissions, contains(permission));
      }
    });

    test('supporter receives dashboard and read-only platform access', () {
      final permissions =
          AdminPermissionMatrix.permissionsForRole(StaffRole.supporter);

      expect(permissions, contains(StaffPermission.dashboardView));
      expect(permissions, contains(StaffPermission.usersView));
      expect(permissions, contains(StaffPermission.venuesView));
      expect(permissions, contains(StaffPermission.venueClaimsView));
      expect(permissions, contains(StaffPermission.adminMapView));
      expect(permissions, isNot(contains(StaffPermission.venuesEdit)));
      expect(permissions, isNot(contains(StaffPermission.staffView)));
    });

    test('coordinator adds venue editing and claim moderation', () {
      final permissions =
          AdminPermissionMatrix.permissionsForRole(StaffRole.coordinator);

      expect(
        permissions,
        containsAll(
          AdminPermissionMatrix.permissionsForRole(StaffRole.supporter),
        ),
      );
      expect(permissions, contains(StaffPermission.venuesEdit));
      expect(permissions, contains(StaffPermission.venueClaimApprove));
      expect(permissions, contains(StaffPermission.venueClaimAssign));
      expect(permissions, contains(StaffPermission.reportsModerate));
      expect(permissions, isNot(contains(StaffPermission.drinksManage)));
    });

    test('admin adds content management and staff view', () {
      final permissions = AdminPermissionMatrix.permissionsForRole(StaffRole.admin);

      expect(
        permissions,
        containsAll(
          AdminPermissionMatrix.permissionsForRole(StaffRole.coordinator),
        ),
      );
      expect(permissions, contains(StaffPermission.drinksManage));
      expect(permissions, contains(StaffPermission.dealsManage));
      expect(permissions, contains(StaffPermission.eventsManage));
      expect(permissions, contains(StaffPermission.usersEdit));
      expect(permissions, contains(StaffPermission.analyticsView));
      expect(permissions, contains(StaffPermission.staffView));
      expect(permissions, isNot(contains(StaffPermission.staffInvite)));
    });

    test('super admin adds staff management and subscriptions', () {
      final permissions =
          AdminPermissionMatrix.permissionsForRole(StaffRole.superAdmin);

      expect(
        permissions,
        containsAll(AdminPermissionMatrix.permissionsForRole(StaffRole.admin)),
      );
      expect(permissions, contains(StaffPermission.staffInvite));
      expect(permissions, contains(StaffPermission.staffEdit));
      expect(permissions, contains(StaffPermission.staffRemove));
      expect(permissions, contains(StaffPermission.staffRoleChange));
      expect(permissions, contains(StaffPermission.subscriptionsManage));
      expect(permissions, contains(StaffPermission.systemMonitoringView));
      expect(permissions, isNot(contains(StaffPermission.auditView)));
    });

    test('management adds audit, financials, and platform settings', () {
      final permissions =
          AdminPermissionMatrix.permissionsForRole(StaffRole.management);

      expect(
        permissions,
        containsAll(
          AdminPermissionMatrix.permissionsForRole(StaffRole.superAdmin),
        ),
      );
      expect(permissions, contains(StaffPermission.staffManageSuperAdmins));
      expect(permissions, contains(StaffPermission.financials));
      expect(permissions, contains(StaffPermission.auditView));
      expect(permissions, contains(StaffPermission.systemSettings));
      expect(permissions, contains(StaffPermission.usersDelete));
    });
  });

  group('StaffRole', () {
    test('fromLevel resolves tier boundaries', () {
      expect(StaffRole.fromLevel(10), StaffRole.supporter);
      expect(StaffRole.fromLevel(20), StaffRole.coordinator);
      expect(StaffRole.fromLevel(30), StaffRole.admin);
      expect(StaffRole.fromLevel(50), StaffRole.superAdmin);
      expect(StaffRole.fromLevel(60), StaffRole.management);
      expect(StaffRole.fromLevel(100), StaffRole.founder);
    });

    test('fromName resolves known role strings', () {
      expect(StaffRole.fromName('super_admin'), StaffRole.superAdmin);
      expect(StaffRole.fromName('Founder'), StaffRole.founder);
    });
  });
}
