import 'package:vex_core/vex_core.dart';

import '../../features/auth/services/user_role_service.dart';

DashboardRole dashboardRoleFromVexda(VexdaUserRole role) {
  return switch (role) {
    VexdaUserRole.admin => DashboardRole.admin,
    VexdaUserRole.venueOwner => DashboardRole.venueOwner,
    VexdaUserRole.employee => DashboardRole.employee,
    VexdaUserRole.regularUser => DashboardRole.regularUser,
  };
}

VexdaUserRole vexdaRoleFromDashboard(DashboardRole role) {
  return switch (role) {
    DashboardRole.admin => VexdaUserRole.admin,
    DashboardRole.venueOwner => VexdaUserRole.venueOwner,
    DashboardRole.employee => VexdaUserRole.employee,
    DashboardRole.regularUser => VexdaUserRole.regularUser,
  };
}

VexIdentity identityFromUserRoleProfile({
  required String uid,
  String? email,
  required UserRoleProfile profile,
}) {
  return VexIdentity.fromProfile(
    uid: uid,
    email: email,
    dashboardRole: dashboardRoleFromVexda(profile.role),
    venueIds: profile.venueIds,
    roleLevel: profile.roleLevel,
    staffFlag: profile.staffFlag,
    isAdminFlag: profile.isAdminFlag,
    ownedVenuesCount: profile.ownedVenuesCount,
    resolutionSource: profile.source,
  );
}

UserRoleProfile userRoleProfileFromIdentity(VexIdentity identity) {
  return UserRoleProfile(
    role: vexdaRoleFromDashboard(identity.dashboardRole),
    venueIds: identity.venueIds,
    isAdminFlag: identity.isAdminFlag,
    ownedVenuesCount: identity.ownedVenuesCount,
    roleLevel: identity.roleLevel,
    staffFlag: identity.staffFlag,
    source: identity.resolutionSource,
  );
}
