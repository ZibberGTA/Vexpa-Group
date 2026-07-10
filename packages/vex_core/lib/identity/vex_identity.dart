import 'account_status.dart';
import 'dashboard_role.dart';
import 'vex_role.dart';

final class VexIdentity {
  const VexIdentity({
    required this.uid,
    required this.roles,
    required this.status,
    required this.dashboardRole,
    this.email,
    this.venueIds = const <String>[],
    this.roleLevel = 0,
    this.staffFlag = false,
    this.isAdminFlag = false,
    this.ownedVenuesCount = 0,
    this.resolutionSource = 'unknown',
  });

  final String uid;
  final String? email;
  final Set<VexRole> roles;
  final AccountStatus status;
  final DashboardRole dashboardRole;
  final List<String> venueIds;
  final int roleLevel;
  final bool staffFlag;
  final bool isAdminFlag;
  final int ownedVenuesCount;
  final String resolutionSource;

  /// Maps a resolved dashboard role to VexCore role tags.
  static Set<VexRole> rolesForDashboardRole(DashboardRole dashboardRole) {
    return switch (dashboardRole) {
      DashboardRole.admin => {VexRole.admin, VexRole.staff},
      DashboardRole.venueOwner => {VexRole.owner},
      DashboardRole.employee => {VexRole.staff},
      DashboardRole.regularUser => {VexRole.user},
    };
  }

  factory VexIdentity.fromProfile({
    required String uid,
    String? email,
    required DashboardRole dashboardRole,
    AccountStatus status = AccountStatus.active,
    List<String> venueIds = const [],
    int roleLevel = 0,
    bool staffFlag = false,
    bool isAdminFlag = false,
    int ownedVenuesCount = 0,
    String resolutionSource = 'unknown',
  }) {
    return VexIdentity(
      uid: uid,
      email: email,
      roles: rolesForDashboardRole(dashboardRole),
      status: status,
      dashboardRole: dashboardRole,
      venueIds: venueIds,
      roleLevel: roleLevel,
      staffFlag: staffFlag,
      isAdminFlag: isAdminFlag,
      ownedVenuesCount: ownedVenuesCount,
      resolutionSource: resolutionSource,
    );
  }
}
