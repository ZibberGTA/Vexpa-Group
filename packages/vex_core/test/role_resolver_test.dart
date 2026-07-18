import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  group('RoleResolver.isValidStaffDocument', () {
    test('accepts staff flag', () {
      expect(
        RoleResolver.isValidStaffDocument(const {'staff': true}),
        isTrue,
      );
    });

    test('accepts roleLevel >= 30', () {
      expect(
        RoleResolver.isValidStaffDocument(const {'roleLevel': 30}),
        isTrue,
      );
    });

    test('accepts admin role aliases', () {
      expect(
        RoleResolver.isValidStaffDocument(const {'role': 'founder'}),
        isTrue,
      );
    });

    test('rejects regular user docs', () {
      expect(
        RoleResolver.isValidStaffDocument(const {'role': 'user'}),
        isFalse,
      );
    });
  });

  group('RoleResolver.resolveFromUserContext', () {
    test('returns venueOwner when owner role is present', () {
      expect(
        RoleResolver.resolveFromUserContext(
          data: const {'role': 'owner'},
          venueIdsCount: 0,
          ownedVenuesCount: 0,
        ),
        DashboardRole.venueOwner,
      );
    });

    test('returns employee when venueIds are assigned', () {
      expect(
        RoleResolver.resolveFromUserContext(
          data: const {'role': 'member'},
          venueIdsCount: 2,
          ownedVenuesCount: 0,
        ),
        DashboardRole.employee,
      );
    });

    test('returns admin for isAdmin shortcut', () {
      expect(
        RoleResolver.resolveFromUserContext(
          data: const {'isAdmin': true, 'role': 'user'},
          venueIdsCount: 0,
          ownedVenuesCount: 0,
        ),
        DashboardRole.admin,
      );
    });

    test('returns venueOwner from owned venues when user doc is missing', () {
      expect(
        RoleResolver.resolveFromUserContext(
          data: null,
          venueIdsCount: 0,
          ownedVenuesCount: 1,
        ),
        DashboardRole.venueOwner,
      );
    });

    test(
      'returns venueOwner when users doc role is user but venues are owned',
      () {
        expect(
          RoleResolver.resolveFromUserContext(
            data: const {'role': 'user'},
            venueIdsCount: 0,
            ownedVenuesCount: 2,
          ),
          DashboardRole.venueOwner,
        );
      },
    );

    test(
      'returns employee when users doc role is user but venueIds are assigned',
      () {
        expect(
          RoleResolver.resolveFromUserContext(
            data: const {'role': 'user'},
            venueIdsCount: 1,
            ownedVenuesCount: 0,
          ),
          DashboardRole.employee,
        );
      },
    );

    test('returns regularUser for customer role without ownership', () {
      expect(
        RoleResolver.resolveFromUserContext(
          data: const {'role': 'user'},
          venueIdsCount: 0,
          ownedVenuesCount: 0,
        ),
        DashboardRole.regularUser,
      );
    });
  });

  group('RoleResolver.resolveStaffFromDocument', () {
    test('normalises admin-eligible staff to admin dashboard role', () {
      final resolution = RoleResolver.resolveStaffFromDocument(
        const {'role': 'coordinator', 'roleLevel': 20, 'staff': true},
        source: 'staffCollection',
      );

      expect(resolution, isNotNull);
      expect(resolution!.dashboardRole, DashboardRole.admin);
      expect(resolution.roleLevel, 30);
      expect(resolution.staffFlag, isTrue);
      expect(resolution.source, 'staffCollection');
    });
  });

  group('RoleResolver.wouldDowngradeRole', () {
    test('admin to regular user is a downgrade', () {
      expect(
        RoleResolver.wouldDowngradeRole(
          DashboardRole.admin,
          DashboardRole.regularUser,
        ),
        isTrue,
      );
    });

    test('venueOwner to employee is not a downgrade', () {
      expect(
        RoleResolver.wouldDowngradeRole(
          DashboardRole.venueOwner,
          DashboardRole.employee,
        ),
        isFalse,
      );
    });
  });
}
