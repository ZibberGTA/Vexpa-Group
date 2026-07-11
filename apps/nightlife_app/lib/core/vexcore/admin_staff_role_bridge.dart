import 'package:vex_core/vex_core.dart' as vex;

import '../../features/admin/services/admin_permission_service.dart';

/// Bridges mobile admin [StaffRole] values to VexCore staff permissions.
abstract final class AdminStaffRoleBridge {
  AdminStaffRoleBridge._();

  static vex.StaffRole toVexCore(StaffRole role) {
    return switch (role) {
      StaffRole.support => vex.StaffRole.supporter,
      StaffRole.admin => vex.StaffRole.admin,
      StaffRole.management => vex.StaffRole.management,
      StaffRole.founder => vex.StaffRole.founder,
    };
  }

  static bool hasPermission(StaffRole role, vex.StaffPermission permission) {
    return vex.AdminPermissionMatrix.hasPermission(toVexCore(role), permission);
  }

  static bool hasAnyPermission(
    StaffRole role,
    Iterable<vex.StaffPermission> permissions,
  ) {
    return vex.AdminPermissionMatrix.hasAnyPermission(
      toVexCore(role),
      permissions,
    );
  }
}
