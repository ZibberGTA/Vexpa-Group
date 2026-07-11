import 'package:vex_core/vex_core.dart';

import '../../features/auth/services/user_role_service.dart';

DashboardRole dashboardRoleFromAppUserRole(AppUserRole role) {
  return switch (role) {
    AppUserRole.founder ||
    AppUserRole.management ||
    AppUserRole.admin =>
      DashboardRole.admin,
    AppUserRole.owner => DashboardRole.venueOwner,
    AppUserRole.employee => DashboardRole.employee,
    AppUserRole.artist || AppUserRole.user => DashboardRole.regularUser,
  };
}

AppUserRole appUserRoleFromDashboard(
  DashboardRole role, {
  int roleLevel = 0,
  String? rawRole,
}) {
  return switch (role) {
    DashboardRole.venueOwner => AppUserRole.owner,
    DashboardRole.employee => AppUserRole.employee,
    DashboardRole.regularUser => AppUserRole.user,
    DashboardRole.admin => UserRoleService.parseStaffAdminRole(
        roleLevel: roleLevel,
        rawRole: rawRole,
      ),
  };
}

VexIdentity identityFromRoleSnapshot(UserRoleSnapshot snapshot) {
  return VexIdentity.fromProfile(
    uid: snapshot.uid,
    email: snapshot.email,
    dashboardRole: dashboardRoleFromAppUserRole(snapshot.role),
    venueIds: snapshot.venueIds,
    roleLevel: snapshot.roleLevel,
    staffFlag: snapshot.staffFlag,
    isAdminFlag: snapshot.isAdminFlag,
    ownedVenuesCount: snapshot.ownedVenuesCount,
    resolutionSource: snapshot.source,
  );
}
