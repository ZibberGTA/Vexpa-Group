import 'dashboard_role.dart';

/// Resolved staff role metadata from a staff document or custom claims.
final class StaffRoleResolution {
  const StaffRoleResolution({
    required this.dashboardRole,
    required this.roleLevel,
    required this.staffFlag,
    required this.source,
  });

  final DashboardRole dashboardRole;
  final int roleLevel;
  final bool staffFlag;
  final String source;
}

/// Firestore-backed role profile for a signed-in user.
final class ResolvedIdentityProfile {
  const ResolvedIdentityProfile({
    required this.dashboardRole,
    this.venueIds = const [],
    this.isAdminFlag = false,
    this.ownedVenuesCount = 0,
    this.roleLevel = 0,
    this.staffFlag = false,
    this.source = 'unknown',
  });

  final DashboardRole dashboardRole;
  final List<String> venueIds;
  final bool isAdminFlag;
  final int ownedVenuesCount;
  final int roleLevel;
  final bool staffFlag;
  final String source;
}

/// Pure role resolution logic shared across Vexda clients.
abstract final class RoleResolver {
  RoleResolver._();

  static List<String> parseVenueIds(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  static String? readRoleField(Map<String, dynamic>? data) {
    if (data == null) return null;

    final role = data['role']?.toString().trim();
    if (role != null && role.isNotEmpty) return role;

    final accountType = data['accountType']?.toString().trim();
    if (accountType != null && accountType.isNotEmpty) return accountType;

    return null;
  }

  static int readRoleLevel(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  static bool readStaffFlag(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['staff'] == true || data['isStaff'] == true;
  }

  static bool isAdminRoleName(String rawRole) {
    final role = rawRole.trim().toLowerCase();
    return role == 'admin' ||
        role == 'founder' ||
        role == 'management' ||
        role == 'manager' ||
        role == 'staff' ||
        role == 'owner_founder' ||
        role == 'app_owner';
  }

  /// True when a `staff/{uid}` document grants admin/staff dashboard access.
  static bool isValidStaffDocument(Map<String, dynamic>? data) {
    if (data == null) return false;

    if (readStaffFlag(data)) return true;

    if (readRoleLevel(data['roleLevel']) >= 30) return true;

    final staffRole = (data['role'] ?? '').toString().trim().toLowerCase();
    return isAdminRoleName(staffRole);
  }

  static StaffRoleResolution? resolveStaffFromDocument(
    Map<String, dynamic> data, {
    required String source,
  }) {
    if (!isValidStaffDocument(data)) return null;

    final roleLevel = readRoleLevel(data['roleLevel']);
    final staffRole = (data['role'] ?? '').toString().trim().toLowerCase();

    return StaffRoleResolution(
      dashboardRole: DashboardRole.admin,
      roleLevel: roleLevel >= 30 ? roleLevel : 30,
      staffFlag:
          readStaffFlag(data) ||
          roleLevel >= 30 ||
          isAdminRoleName(staffRole),
      source: source,
    );
  }

  static StaffRoleResolution? resolveStaffFromClaims(
    Map<String, dynamic> claims,
  ) {
    final roleLevel = readRoleLevel(claims['roleLevel']);
    final staffFlag = claims['staff'] == true;
    final staffRole = (claims['staffRole'] ?? claims['role'] ?? '')
        .toString()
        .trim();

    if (!staffFlag && roleLevel < 30 && !isAdminRoleName(staffRole)) {
      return null;
    }

    return resolveStaffFromDocument({
      'role': staffRole.isEmpty ? 'admin' : staffRole,
      'roleLevel': roleLevel,
      'staff': staffFlag,
    }, source: 'customClaims');
  }

  /// Parses `users/{uid}.role` plus optional `isAdmin` and `venueIds`.
  ///
  /// Does not check owned venues — use [resolveFromUserContext] for full access.
  static DashboardRole parseUserDocument(Map<String, dynamic>? data) {
    return resolveFromUserContext(
      data: data,
      venueIdsCount: parseVenueIds(data?['venueIds']).length,
      ownedVenuesCount: 0,
    );
  }

  static DashboardRole resolveFromUserContext({
    required Map<String, dynamic>? data,
    required int venueIdsCount,
    required int ownedVenuesCount,
  }) {
    if (data == null) {
      return ownedVenuesCount > 0
          ? DashboardRole.venueOwner
          : DashboardRole.regularUser;
    }

    if (data['isAdmin'] == true) {
      return DashboardRole.admin;
    }

    final roleLevel = readRoleLevel(data['roleLevel']);
    if (roleLevel >= 30) {
      return DashboardRole.admin;
    }

    final rawRole = (readRoleField(data) ?? 'user').trim().toLowerCase();

    if (rawRole == 'staff') {
      if (readStaffFlag(data) || roleLevel >= 30) return DashboardRole.admin;
      if (venueIdsCount > 0) return DashboardRole.employee;
      return DashboardRole.admin;
    }

    if (rawRole == 'employee') return DashboardRole.employee;

    if (isAdminRoleName(rawRole)) {
      return DashboardRole.admin;
    }

    if (rawRole == 'owner' ||
        rawRole == 'venueowner' ||
        rawRole == 'venue_owner' ||
        rawRole == 'business' ||
        rawRole == 'businessowner' ||
        rawRole == 'business_owner' ||
        rawRole == 'venue') {
      return DashboardRole.venueOwner;
    }

    if (rawRole == 'customer' || rawRole == 'user') {
      if (ownedVenuesCount > 0) return DashboardRole.venueOwner;
      if (venueIdsCount > 0) return DashboardRole.employee;
      return DashboardRole.regularUser;
    }

    if (venueIdsCount > 0) return DashboardRole.employee;

    if (ownedVenuesCount > 0) return DashboardRole.venueOwner;

    return DashboardRole.regularUser;
  }

  static ResolvedIdentityProfile profileFromStaffResolution(
    StaffRoleResolution staff,
  ) {
    return ResolvedIdentityProfile(
      dashboardRole: DashboardRole.admin,
      isAdminFlag: true,
      roleLevel: staff.roleLevel,
      staffFlag: staff.staffFlag,
      source: staff.source,
    );
  }

  static bool wouldDowngradeRole(
    DashboardRole current,
    DashboardRole next,
  ) {
    if (current == next) return false;

    if (current == DashboardRole.admin) {
      return next != DashboardRole.admin;
    }

    return next == DashboardRole.regularUser &&
        current != DashboardRole.regularUser;
  }
}
