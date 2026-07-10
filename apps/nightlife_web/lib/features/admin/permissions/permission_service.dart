import 'staff_permission.dart';
import 'staff_role.dart';

/// Central permission engine for the Vexda admin platform.
///
/// Use [has], [hasAny], and [hasAll] instead of comparing role levels in UI
/// or business logic. Role-to-permission mappings live here only.
class PermissionService {
  PermissionService._(this._granted);

  factory PermissionService.forRole(StaffRole role) {
    return PermissionService._(permissionsForRole(role));
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
    return switch (role) {
      StaffRole.founder => StaffPermission.values.toSet(),
      StaffRole.management => {
        ...permissionsForRole(StaffRole.superAdmin),
        ..._managementPermissions,
      },
      StaffRole.superAdmin => {
        ...permissionsForRole(StaffRole.admin),
        ..._superAdminPermissions,
      },
      StaffRole.admin => {
        ...permissionsForRole(StaffRole.coordinator),
        ..._adminPermissions,
      },
      StaffRole.coordinator => {
        ...permissionsForRole(StaffRole.supporter),
        ..._coordinatorPermissions,
      },
      StaffRole.supporter => Set.unmodifiable(_supporterPermissions),
    };
  }

  static const Set<StaffPermission> _supporterPermissions = {
    StaffPermission.dashboardView,
    StaffPermission.usersView,
    StaffPermission.venuesView,
    StaffPermission.venueClaimsView,
    StaffPermission.adminMapView,
  };

  static const Set<StaffPermission> _coordinatorPermissions = {
    StaffPermission.venuesEdit,
    StaffPermission.venueClaimApprove,
    StaffPermission.venueClaimAssign,
    StaffPermission.reportsView,
    StaffPermission.reportsModerate,
  };

  static const Set<StaffPermission> _adminPermissions = {
    StaffPermission.drinksView,
    StaffPermission.drinksManage,
    StaffPermission.dealsView,
    StaffPermission.dealsManage,
    StaffPermission.eventsView,
    StaffPermission.eventsManage,
    StaffPermission.trailsView,
    StaffPermission.trailsManage,
    StaffPermission.usersEdit,
    StaffPermission.usersSuspend,
    StaffPermission.analyticsView,
    StaffPermission.reportsManage,
    StaffPermission.staffView,
    StaffPermission.venuesDelete,
    StaffPermission.venueApprove,
    StaffPermission.paymentsView,
    StaffPermission.searchIntelligenceView,
    StaffPermission.venueIntelligenceView,
  };

  static const Set<StaffPermission> _superAdminPermissions = {
    StaffPermission.staffInvite,
    StaffPermission.staffEdit,
    StaffPermission.staffRemove,
    StaffPermission.staffRoleChange,
    StaffPermission.subscriptionsView,
    StaffPermission.subscriptionsManage,
    StaffPermission.paymentsManage,
    StaffPermission.platformNotificationsManage,
    StaffPermission.systemMonitoringView,
    StaffPermission.analyticsAdvanced,
  };

  static const Set<StaffPermission> _managementPermissions = {
    StaffPermission.staffManageSuperAdmins,
    StaffPermission.financials,
    StaffPermission.auditView,
    StaffPermission.systemSettings,
    StaffPermission.usersDelete,
  };
}
