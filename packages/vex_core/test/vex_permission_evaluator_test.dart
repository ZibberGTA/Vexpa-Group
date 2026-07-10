import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  const evaluator = VexPermissionEvaluator();

  group('VexPermissionEvaluator', () {
    test('allows admin portal for admin dashboard identities', () async {
      final decision = await evaluator.evaluate(
        identity: VexIdentity.fromProfile(
          uid: 'admin-1',
          dashboardRole: DashboardRole.admin,
          roleLevel: 30,
          staffFlag: true,
        ),
        permission: VexPermission.accessAdminPortal,
      );

      expect(decision.isAllowed, isTrue);
    });

    test('denies admin portal for venue owners', () async {
      final decision = await evaluator.evaluate(
        identity: VexIdentity.fromProfile(
          uid: 'owner-1',
          dashboardRole: DashboardRole.venueOwner,
        ),
        permission: VexPermission.accessAdminPortal,
      );

      expect(decision.isAllowed, isFalse);
    });

    test('maps manageStaff to admin staff permissions', () async {
      final allowed = await evaluator.evaluate(
        identity: VexIdentity.fromProfile(
          uid: 'super-admin',
          dashboardRole: DashboardRole.admin,
          roleLevel: 50,
        ),
        permission: VexPermission.manageStaff,
      );
      final denied = await evaluator.evaluate(
        identity: VexIdentity.fromProfile(
          uid: 'supporter',
          dashboardRole: DashboardRole.admin,
          roleLevel: 10,
        ),
        permission: VexPermission.manageStaff,
      );

      expect(allowed.isAllowed, isTrue);
      expect(denied.isAllowed, isFalse);
    });
  });
}
