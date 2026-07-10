import '../identity/staff_role.dart';
import 'staff_permission.dart';

/// Pure admin permission matrix shared across Vexda clients.
abstract final class AdminPermissionMatrix {
  AdminPermissionMatrix._();

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

  static bool hasPermission(StaffRole role, StaffPermission permission) {
    return permissionsForRole(role).contains(permission);
  }

  static bool hasAnyPermission(
    StaffRole role,
    Iterable<StaffPermission> permissions,
  ) {
    final granted = permissionsForRole(role);
    for (final permission in permissions) {
      if (granted.contains(permission)) return true;
    }
    return false;
  }

  static bool hasAllPermissions(
    StaffRole role,
    Iterable<StaffPermission> permissions,
  ) {
    final granted = permissionsForRole(role);
    for (final permission in permissions) {
      if (!granted.contains(permission)) return false;
    }
    return true;
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
