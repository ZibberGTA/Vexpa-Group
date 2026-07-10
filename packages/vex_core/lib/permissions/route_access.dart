import '../identity/account_status.dart';
import '../identity/dashboard_role.dart';
import '../identity/vex_identity.dart';

/// Route access predicates for dashboard guards.
abstract final class RouteAccess {
  RouteAccess._();

  static bool canAccessAdminPortal(VexIdentity identity) {
    if (!_isAccountEligible(identity.status)) return false;
    return canAccessAdminDashboard(identity.dashboardRole);
  }

  static bool canAccessVenueDashboard(VexIdentity identity) {
    if (!_isAccountEligible(identity.status)) return false;
    return canAccessVenueDashboardRole(identity.dashboardRole);
  }

  static bool _isAccountEligible(AccountStatus status) {
    return status == AccountStatus.active;
  }

  static bool canAccessAdminDashboard(DashboardRole role) {
    return role.canAccessAdminDashboard;
  }

  static bool canAccessVenueDashboardRole(DashboardRole role) {
    return role.canAccessVenueDashboard;
  }
}
