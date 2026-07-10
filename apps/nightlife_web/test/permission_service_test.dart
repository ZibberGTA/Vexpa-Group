import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/admin/permissions/permissions.dart';

void main() {
  group('PermissionService.permissionsForRole', () {
    test('founder receives every permission', () {
      final permissions = PermissionService.permissionsForRole(StaffRole.founder);

      expect(permissions.length, StaffPermission.values.length);
      for (final permission in StaffPermission.values) {
        expect(permissions, contains(permission));
      }
    });

    test('supporter receives dashboard and read-only platform access', () {
      final permissions = PermissionService.permissionsForRole(StaffRole.supporter);

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
          PermissionService.permissionsForRole(StaffRole.coordinator);

      expect(permissions, containsAll(PermissionService.permissionsForRole(StaffRole.supporter)));
      expect(permissions, contains(StaffPermission.venuesEdit));
      expect(permissions, contains(StaffPermission.venueClaimApprove));
      expect(permissions, contains(StaffPermission.venueClaimAssign));
      expect(permissions, contains(StaffPermission.reportsModerate));
      expect(permissions, isNot(contains(StaffPermission.drinksManage)));
    });

    test('admin adds content management and staff view', () {
      final permissions = PermissionService.permissionsForRole(StaffRole.admin);

      expect(permissions, containsAll(PermissionService.permissionsForRole(StaffRole.coordinator)));
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
          PermissionService.permissionsForRole(StaffRole.superAdmin);

      expect(permissions, containsAll(PermissionService.permissionsForRole(StaffRole.admin)));
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
          PermissionService.permissionsForRole(StaffRole.management);

      expect(permissions, containsAll(PermissionService.permissionsForRole(StaffRole.superAdmin)));
      expect(permissions, contains(StaffPermission.staffManageSuperAdmins));
      expect(permissions, contains(StaffPermission.financials));
      expect(permissions, contains(StaffPermission.auditView));
      expect(permissions, contains(StaffPermission.systemSettings));
      expect(permissions, contains(StaffPermission.usersDelete));
    });
  });

  group('PermissionService.has', () {
    test('returns true only for granted permissions', () {
      final permissions = PermissionService.forRole(StaffRole.admin);

      expect(permissions.has(StaffPermission.staffView), isTrue);
      expect(permissions.has(StaffPermission.staffInvite), isFalse);
      expect(permissions.has(StaffPermission.financials), isFalse);
    });

    test('fromRoleLevel maps numeric levels to permission sets', () {
      final permissions = PermissionService.fromRoleLevel(50);

      expect(permissions.has(StaffPermission.staffInvite), isTrue);
      expect(permissions.has(StaffPermission.auditView), isFalse);
    });

    test('fromRoleName maps role strings to permission sets', () {
      final permissions = PermissionService.fromRoleName('management');

      expect(permissions.has(StaffPermission.auditView), isTrue);
      expect(permissions.has(StaffPermission.staffInvite), isTrue);
    });
  });

  group('PermissionService.hasAny', () {
    test('returns true when at least one permission is granted', () {
      final permissions = PermissionService.forRole(StaffRole.coordinator);

      expect(
        permissions.hasAny([
          StaffPermission.financials,
          StaffPermission.venuesEdit,
        ]),
        isTrue,
      );
      expect(
        permissions.hasAny([
          StaffPermission.financials,
          StaffPermission.staffInvite,
        ]),
        isFalse,
      );
    });
  });

  group('PermissionService.hasAll', () {
    test('returns true only when every permission is granted', () {
      final permissions = PermissionService.forRole(StaffRole.supporter);

      expect(
        permissions.hasAll([
          StaffPermission.dashboardView,
          StaffPermission.usersView,
        ]),
        isTrue,
      );
      expect(
        permissions.hasAll([
          StaffPermission.dashboardView,
          StaffPermission.staffInvite,
        ]),
        isFalse,
      );
    });

    test('founder satisfies hasAll for every permission', () {
      final permissions = PermissionService.forRole(StaffRole.founder);

      expect(permissions.hasAll(StaffPermission.values), isTrue);
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
