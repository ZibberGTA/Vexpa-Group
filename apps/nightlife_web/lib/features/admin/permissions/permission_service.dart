import 'package:vex_core/vex_core.dart';

/// Central permission engine for the Vexda admin platform.
///
/// Use [has], [hasAny], and [hasAll] instead of comparing role levels in UI
/// or business logic. Role-to-permission mappings live in VexCore.
class PermissionService {
  PermissionService._(this._granted);

  factory PermissionService.forRole(StaffRole role) {
    return PermissionService._(AdminPermissionMatrix.permissionsForRole(role));
  }

  /// Bridge helper until callers migrate off stored [roleLevel] integers.
  factory PermissionService.fromRoleLevel(int roleLevel) {
    return PermissionService.forRole(StaffRole.fromLevel(roleLevel));
  }

  /// Bridge helper until callers migrate off stored role name strings.
  factory PermissionService.fromRoleName(String roleName) {
    return PermissionService.forRole(StaffRole.fromName(roleName));
  }

  final Set<StaffPermission> _granted;

  bool has(StaffPermission permission) => _granted.contains(permission);

  bool hasAny(Iterable<StaffPermission> permissions) {
    for (final permission in permissions) {
      if (has(permission)) return true;
    }
    return false;
  }

  bool hasAll(Iterable<StaffPermission> permissions) {
    for (final permission in permissions) {
      if (!has(permission)) return false;
    }
    return true;
  }

  Set<StaffPermission> get grantedPermissions => Set.unmodifiable(_granted);

  static Set<StaffPermission> permissionsForRole(StaffRole role) {
    return AdminPermissionMatrix.permissionsForRole(role);
  }
}
