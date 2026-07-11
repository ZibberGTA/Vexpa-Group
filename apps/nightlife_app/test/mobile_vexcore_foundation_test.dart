import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/core/vexcore/admin_staff_role_bridge.dart';
import 'package:nightlife_app/core/vexcore/mobile_vexcore.dart';
import 'package:nightlife_app/features/admin/services/admin_permission_service.dart';
import 'package:vex_core/vex_core.dart' as vex;

void main() {
  tearDown(MobileVexCore.resetTestOverrides);

  test('MobileVexCore exposes shared singleton platform services', () {
    final authA = MobileVexCore.authentication;
    final authB = MobileVexCore.authentication;
    final identityA = MobileVexCore.identity;
    final identityB = MobileVexCore.identity;
    final busA = MobileVexCore.eventBus;
    final busB = MobileVexCore.eventBus;

    expect(identical(authA, authB), isTrue);
    expect(identical(identityA, identityB), isTrue);
    expect(identical(busA, busB), isTrue);
  });

  test('admin permission checks delegate to VexCore matrix', () {
    expect(
      StaffRole.support.canUseAdminPanel,
      AdminStaffRoleBridge.hasPermission(
        StaffRole.support,
        vex.StaffPermission.dashboardView,
      ),
    );
    expect(
      StaffRole.founder.canViewFinancials,
      AdminStaffRoleBridge.hasPermission(
        StaffRole.founder,
        vex.StaffPermission.financials,
      ),
    );
  });

  test('permission evaluator preserves venue owner dashboard access', () async {
    const evaluator = vex.VexPermissionEvaluator();
    final identity = vex.VexIdentity.fromProfile(
      uid: 'owner-1',
      dashboardRole: vex.DashboardRole.venueOwner,
      venueIds: ['venue-1'],
    );

    final decision = await evaluator.evaluate(
      identity: identity,
      permission: vex.VexPermission.manageVenue,
    );

    expect(decision.isAllowed, isTrue);
  });
}
