import '../identity/staff_role.dart';
import '../identity/vex_identity.dart';
import 'admin_permission_matrix.dart';
import 'permission_decision.dart';
import 'permission_service.dart';
import 'route_access.dart';
import 'staff_permission.dart';
import 'vex_permission.dart';

/// Default VexCore permission evaluator for coarse portal and admin actions.
final class VexPermissionEvaluator implements PermissionService {
  const VexPermissionEvaluator();

  @override
  Future<PermissionDecision> evaluate({
    required VexIdentity identity,
    required VexPermission permission,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    final allowed = switch (permission) {
      VexPermission.accessAdminPortal =>
        RouteAccess.canAccessAdminPortal(identity),
      VexPermission.manageStaff => _hasStaffPermission(
        identity,
        StaffPermission.staffEdit,
      ),
      VexPermission.manageVenue => RouteAccess.canAccessVenueDashboard(identity),
      VexPermission.manageVenueContent => _hasStaffPermission(
        identity,
        StaffPermission.venuesEdit,
      ),
      VexPermission.reviewVenueClaims => _hasStaffPermission(
        identity,
        StaffPermission.venueClaimApprove,
      ),
      VexPermission.viewAnalytics => _hasStaffPermission(
        identity,
        StaffPermission.analyticsView,
      ),
      VexPermission.manageSubscriptions => _hasStaffPermission(
        identity,
        StaffPermission.subscriptionsManage,
      ),
      VexPermission.unknown => false,
    };

    return allowed
        ? PermissionDecision.allow(reason: permission.name)
        : PermissionDecision.deny(reason: permission.name);
  }

  bool hasStaffPermission(VexIdentity identity, StaffPermission permission) {
    return _hasStaffPermission(identity, permission);
  }

  bool _hasStaffPermission(VexIdentity identity, StaffPermission permission) {
    if (!RouteAccess.canAccessAdminPortal(identity)) return false;
    final staffRole = StaffRole.fromLevel(identity.roleLevel);
    return AdminPermissionMatrix.hasPermission(staffRole, permission);
  }
}
