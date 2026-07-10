import 'package:cloud_firestore/cloud_firestore.dart';

import '../permissions/admin_permission_constants.dart';
import '../permissions/permission_service.dart';
import '../permissions/staff_permission.dart';
import 'admin_dashboard_models.dart';

const kAdminUserBackendRequiredTooltip = 'Requires backend function.';

enum AdminUserCrmAction {
  viewProfile,
  editUser,
  suspend,
  unsuspend,
  restoreAccount,
  emailUser,
  deleteUser,
  sendVerificationEmail,
  forcePasswordReset,
  gdprExport,
  requestAccountDeletion,
}

/// Sortable user table column keys.
abstract final class AdminUserTableSortColumn {
  static const name = 'name';
  static const email = 'email';
  static const role = 'role';
  static const status = 'status';
  static const city = 'city';
  static const lastLogin = 'lastLogin';
  static const created = 'created';
  static const updated = 'updated';
  static const savedVenues = 'savedVenues';

  static const defaultColumn = created;
  static const defaultAscending = false;
}

class AdminUserCrmPermissions {
  AdminUserCrmPermissions(this.permissions);

  final PermissionService permissions;

  bool canViewProfile() => permissions.has(StaffPermission.usersView);

  bool canEditUser() => permissions.has(StaffPermission.usersEdit);

  bool canSuspend() => permissions.has(StaffPermission.usersSuspend);

  bool canDeleteActions() => permissions.has(StaffPermission.usersDelete);

  bool isActionAllowed(AdminUserCrmAction action) {
    return switch (action) {
      AdminUserCrmAction.viewProfile => canViewProfile(),
      AdminUserCrmAction.editUser => canEditUser(),
      AdminUserCrmAction.suspend ||
      AdminUserCrmAction.unsuspend => canSuspend(),
      AdminUserCrmAction.restoreAccount ||
      AdminUserCrmAction.emailUser ||
      AdminUserCrmAction.sendVerificationEmail ||
      AdminUserCrmAction.forcePasswordReset => canEditUser(),
      AdminUserCrmAction.deleteUser ||
      AdminUserCrmAction.gdprExport ||
      AdminUserCrmAction.requestAccountDeletion => canDeleteActions(),
    };
  }

  String tooltipFor(AdminUserCrmAction action, {required bool isBackendTodo}) {
    if (isBackendTodo) return kAdminUserBackendRequiredTooltip;
    if (isActionAllowed(action)) {
      return switch (action) {
        AdminUserCrmAction.viewProfile => 'View user profile',
        AdminUserCrmAction.editUser => 'Edit user details',
        AdminUserCrmAction.suspend => 'Suspend user account',
        AdminUserCrmAction.unsuspend => 'Unsuspend user account',
        AdminUserCrmAction.restoreAccount => 'Restore Account',
        AdminUserCrmAction.emailUser => 'Email User',
        AdminUserCrmAction.deleteUser => 'Delete User',
        AdminUserCrmAction.sendVerificationEmail => 'Send verification email',
        AdminUserCrmAction.forcePasswordReset => 'Force password reset',
        AdminUserCrmAction.gdprExport => 'Export GDPR data package',
        AdminUserCrmAction.requestAccountDeletion =>
          'Review account deletion request',
      };
    }
    return kAdminPermissionDeniedTooltip;
  }

  /// Short subtitle for popup menu items and account action tiles.
  String? menuSubtitleFor(
    AdminUserCrmAction action, {
    required bool backendTodo,
  }) {
    if (backendTodo) return kAdminUserBackendRequiredTooltip;
    if (!isActionAllowed(action)) return 'You do not have permission';
    return null;
  }
}

class AdminUserCrmView {
  const AdminUserCrmView({required this.row});

  final AdminDocumentRow row;

  String get uid => row.id;

  String get displayName => row.readString([
    'displayName',
    'name',
    'fullName',
  ], fallback: 'Unnamed user');

  String get email => row.readString(['email']);

  String get phone => row.readString(['phone', 'phoneNumber']);

  String get city => row.readString(['city', 'area', 'location']);

  String get role => row.readString(['role'], fallback: 'user');

  String get accountType {
    final explicit = row.readString([
      'accountType',
      'userType',
      'customerType',
    ], fallback: '');
    if (explicit.isNotEmpty && explicit != '—')
      return explicit.trim().toLowerCase();
    if (row.readBool(['isGuest'])) return 'guest';
    if (isVenueOwnerRole) return 'venue_owner';
    if (isArtistRole) return 'artist';
    return 'standard';
  }

  String get accountTypeLabel {
    return switch (accountType) {
      'guest' => 'Guest',
      'venue_owner' => 'Venue owner',
      'artist' => 'Artist',
      'standard' => 'Standard',
      _ =>
        accountType
            .split(RegExp(r'[_\s]+'))
            .where((part) => part.isNotEmpty)
            .map(
              (part) =>
                  '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
            )
            .join(' '),
    };
  }

  String get status {
    final raw = row.readString(['status'], fallback: '').trim().toLowerCase();
    if (raw.isNotEmpty && raw != '—') return raw;
    if (row.readBool(['isGuest'])) return 'guest';
    if (row.readBool(['deletionRequested'])) return 'deletion requested';
    return 'active';
  }

  String get statusLabel {
    final value = status;
    if (value.isEmpty || value == '—') return 'Active';
    return value[0].toUpperCase() + value.substring(1);
  }

  bool get isSuspended =>
      status == 'suspended' || row.readBool(['isSuspended']);

  bool get isDeleted => row.data['isDeleted'] == true || status == 'deleted';

  bool get isDisabled => row.readBool(['disabled']) || status == 'disabled';

  bool get needsRestore =>
      !isDeleted &&
      (isSuspended || isDisabled || status == 'deletion requested');

  bool get hasEmail {
    final value = email.trim();
    return value.isNotEmpty && value != '—';
  }

  bool get isStaffAdminRole {
    return const {
      'admin',
      'superadmin',
      'superadministrator',
      'founder',
      'management',
    }.contains(normalizedRole);
  }

  bool get isVerified {
    if (row.readBool(['verified', 'emailVerified', 'isVerified'])) return true;
    final raw = row.readString(['verified'], fallback: '').toLowerCase();
    return raw == 'true' || raw == 'verified';
  }

  String get verifiedLabel => isVerified ? 'Verified' : 'Unverified';

  String get createdAt => readDate(const ['createdAt', 'created_at']);

  String get updatedAt => readDate(const ['updatedAt', 'updated_at']);

  String get lastLogin => readDate(const [
    'lastLoginAt',
    'lastLogin',
    'lastSignInTime',
    'lastSignInAt',
  ]);

  DateTime? get sortableLastLogin => readDateTime(const [
    'lastLoginAt',
    'lastLogin',
    'lastSignInTime',
    'lastSignInAt',
  ]);

  DateTime? get sortableUpdatedAt =>
      readDateTime(const ['updatedAt', 'updated_at']);

  String get lastLoginLabel {
    final timestamp = sortableLastLogin;
    if (timestamp != null) return formatDateTime(timestamp);
    final raw = lastLogin;
    if (raw.isNotEmpty && raw != '—') return raw;
    return 'Never';
  }

  String get lastActive => readDate(const [
    'lastActiveAt',
    'lastActive',
    'lastSeenAt',
    'lastActivityAt',
  ]);

  String? get savedVenuesCountLabel {
    final count = savedVenuesCount;
    if (count == null) return null;
    return count.toString();
  }

  int? get savedVenuesCount {
    final explicit =
        row.data['savedVenuesCount'] ?? row.data['favouritesCount'];
    if (explicit is num) return explicit.toInt();
    final ids = row.data['savedVenueIds'] ?? row.data['savedVenues'];
    if (ids is List) return ids.length;
    return null;
  }

  Map<String, dynamic>? get notificationPreferences {
    final prefs = row.data['notificationPreferences'];
    if (prefs is Map<String, dynamic>) return prefs;
    return null;
  }

  bool get deletionRequested => row.readBool(['deletionRequested']);

  String get internalNotes =>
      row.readString(['internalNotes', 'notes'], fallback: '—');

  String get searchBlob =>
      [displayName, email, city, role, status, uid].join(' ').toLowerCase();

  DateTime? get sortableCreatedAt =>
      readDateTime(const ['createdAt', 'created_at']);

  DateTime? get sortableLastActive => readDateTime(const [
    'lastActiveAt',
    'lastActive',
    'lastSeenAt',
    'lastActivityAt',
    'lastLoginAt',
    'lastLogin',
  ]);

  String readDate(List<String> keys) {
    for (final key in keys) {
      final value = row.data[key];
      if (value == null) continue;
      if (value is Timestamp) return formatDateTime(value.toDate());
      if (value is DateTime) return formatDateTime(value);
      if (value is int) {
        final millis = value > 9999999999 ? value : value * 1000;
        return formatDateTime(
          DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal(),
        );
      }
      if (value is num) {
        final millis = value > 9999999999
            ? value.toInt()
            : (value * 1000).toInt();
        return formatDateTime(
          DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal(),
        );
      }
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '—';
  }

  DateTime? readDateTime(List<String> keys) {
    for (final key in keys) {
      final value = row.data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          value > 9999999999 ? value : value * 1000,
          isUtc: true,
        ).toLocal();
      }
      if (value is num) {
        final millis = value > 9999999999
            ? value.toInt()
            : (value * 1000).toInt();
        return DateTime.fromMillisecondsSinceEpoch(
          millis,
          isUtc: true,
        ).toLocal();
      }
    }
    return null;
  }

  static String formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get normalizedRole =>
      role.toLowerCase().replaceAll('_', '').replaceAll(' ', '');

  bool get isVenueOwnerRole {
    return const {
      'owner',
      'venueowner',
      'businessowner',
      'business',
    }.contains(normalizedRole);
  }

  bool get isArtistRole => normalizedRole == 'artist';

  bool get hasVenueIdsOnProfile {
    final ids = row.data['venueIds'];
    return ids is List && ids.isNotEmpty;
  }

  bool get shouldLoadVenueOwnerContext =>
      isVenueOwnerRole || hasVenueIdsOnProfile;

  bool get shouldLoadArtistContext => isArtistRole;

  AdminUserCrmContextType resolveContextType(
    AdminUserSupplementaryData? supplementary,
  ) {
    if (shouldLoadVenueOwnerContext ||
        (supplementary?.venueOwner?.ownedVenuesCount ?? 0) > 0) {
      return AdminUserCrmContextType.venueOwner;
    }
    if (isArtistRole || (supplementary?.artist?.hasProfile ?? false)) {
      return AdminUserCrmContextType.artist;
    }
    return AdminUserCrmContextType.customer;
  }
}

enum AdminUserCrmContextType { venueOwner, artist, customer }

class AdminUserVenueOwnerContext {
  const AdminUserVenueOwnerContext({
    required this.ownedVenuesCount,
    this.primaryVenue,
    this.drinksCount,
    this.dealsCount,
    this.eventsCount,
    this.unavailable = false,
  });

  final int ownedVenuesCount;
  final AdminDocumentRow? primaryVenue;
  final int? drinksCount;
  final int? dealsCount;
  final int? eventsCount;
  final bool unavailable;

  String get primaryVenueName =>
      primaryVenue?.readString(['name', 'venueName']) ?? '—';

  String get primaryVenueStatus =>
      primaryVenue?.readString(['status', 'claimStatus', 'claimedStatus']) ??
      '—';

  String get claimedVerifiedLabel {
    if (primaryVenue == null) return '—';
    final verified = primaryVenue!.readBool(['isVerified', 'verified']);
    final ownerId = primaryVenue!.readString(['ownerId'], fallback: '');
    if (verified && ownerId.isNotEmpty) return 'Claimed & verified';
    if (ownerId.isNotEmpty) return 'Claimed';
    return 'Not claimed';
  }

  String get subscriptionTier =>
      primaryVenue?.readString([
        'subscriptionPlanId',
        'subscriptionPlan',
        'plan',
      ]) ??
      '—';

  String get subscriptionStatus =>
      primaryVenue?.readString([
        'subscriptionStatus',
        'subscriptionState',
        'billingStatus',
      ]) ??
      '—';

  String get lastVenueUpdate {
    if (primaryVenue == null) return '—';
    return AdminUserCrmView(
      row: primaryVenue!,
    ).readDate(const ['updatedAt', 'updated_at', 'lastUpdatedAt']);
  }

  String? get primaryVenueId => primaryVenue?.id;
}

class AdminUserArtistContext {
  const AdminUserArtistContext({this.profile, this.unavailable = false});

  final AdminDocumentRow? profile;
  final bool unavailable;

  bool get hasProfile => profile != null;

  String get artistName =>
      profile?.readString(['artistName', 'name', 'displayName']) ?? '—';

  String get genre => profile?.readString(['genre', 'genres']) ?? '—';

  String get profileStatus =>
      profile?.readString(['status', 'profileStatus']) ?? '—';

  String get verificationStatus =>
      profile?.readString(['verificationStatus', 'verified', 'isVerified']) ??
      '—';

  String get linkedCountLabel {
    final venues =
        profile?.data['linkedVenueCount'] ?? profile?.data['venueCount'];
    final events =
        profile?.data['linkedEventCount'] ?? profile?.data['eventCount'];
    if (venues is num || events is num) {
      final v = venues is num ? venues.toInt() : 0;
      final e = events is num ? events.toInt() : 0;
      return '$v venues · $e events';
    }
    return '—';
  }

  String get contactEmail =>
      profile?.readString(['email', 'contactEmail']) ?? '—';

  String get websiteOrSocial =>
      profile?.readString([
        'website',
        'websiteUrl',
        'socialLink',
        'instagram',
      ]) ??
      '—';

  String get lastUpdated {
    if (profile == null) return '—';
    return AdminUserCrmView(
      row: profile!,
    ).readDate(const ['updatedAt', 'updated_at']);
  }
}

class AdminUserSupplementaryData {
  const AdminUserSupplementaryData({
    required this.favouritesResult,
    this.deletionRequest,
    required this.reports,
    this.venueOwner,
    this.artist,
  });

  final AdminUserFavouritesResult favouritesResult;
  final Map<String, dynamic>? deletionRequest;
  final List<AdminDocumentRow> reports;
  final AdminUserVenueOwnerContext? venueOwner;
  final AdminUserArtistContext? artist;

  List<AdminDocumentRow> get favourites => favouritesResult.favourites;

  bool get favouritesUnavailable => favouritesResult.isUnavailable;
}

enum AdminUserFavouritesAccess { available, unavailable }

class AdminUserFavouritesResult {
  const AdminUserFavouritesResult({
    required this.favourites,
    required this.access,
  });

  final List<AdminDocumentRow> favourites;
  final AdminUserFavouritesAccess access;

  bool get isUnavailable => access == AdminUserFavouritesAccess.unavailable;
}

List<AdminUserCrmView> filterAndSortUsers({
  required List<AdminDocumentRow> rows,
  required String search,
  required String statusFilter,
  required String roleFilter,
  required String cityFilter,
  required String accountTypeFilter,
  required String sortColumn,
  required bool sortAscending,
}) {
  final query = search.trim().toLowerCase();
  final filtered = rows.map((row) => AdminUserCrmView(row: row)).where((user) {
    if (user.isDeleted) return false;
    if (statusFilter != 'All' && user.status != statusFilter.toLowerCase()) {
      return false;
    }
    if (roleFilter != 'All' &&
        user.role.toLowerCase() != roleFilter.toLowerCase()) {
      return false;
    }
    if (cityFilter != 'All' &&
        user.city.toLowerCase() != cityFilter.toLowerCase()) {
      return false;
    }
    if (accountTypeFilter != 'All' &&
        user.accountTypeLabel.toLowerCase() !=
            accountTypeFilter.toLowerCase()) {
      return false;
    }
    if (query.isNotEmpty && !user.searchBlob.contains(query)) return false;
    return true;
  }).toList();

  filtered.sort((a, b) {
    final result = compareAdminUserRows(a, b, column: sortColumn);
    return sortAscending ? result : -result;
  });

  return filtered;
}

int compareAdminUserRows(
  AdminUserCrmView a,
  AdminUserCrmView b, {
  required String column,
}) {
  return switch (column) {
    AdminUserTableSortColumn.name => a.displayName.toLowerCase().compareTo(
      b.displayName.toLowerCase(),
    ),
    AdminUserTableSortColumn.email => a.email.toLowerCase().compareTo(
      b.email.toLowerCase(),
    ),
    AdminUserTableSortColumn.role => a.role.toLowerCase().compareTo(
      b.role.toLowerCase(),
    ),
    AdminUserTableSortColumn.status => a.status.toLowerCase().compareTo(
      b.status.toLowerCase(),
    ),
    AdminUserTableSortColumn.city => a.city.toLowerCase().compareTo(
      b.city.toLowerCase(),
    ),
    AdminUserTableSortColumn.lastLogin => _compareDateTime(
      a.sortableLastLogin,
      b.sortableLastLogin,
      ascending: true,
    ),
    AdminUserTableSortColumn.created => _compareDateTime(
      a.sortableCreatedAt,
      b.sortableCreatedAt,
      ascending: true,
    ),
    AdminUserTableSortColumn.updated => _compareDateTime(
      a.sortableUpdatedAt,
      b.sortableUpdatedAt,
      ascending: true,
    ),
    AdminUserTableSortColumn.savedVenues =>
      (a.savedVenuesCount ?? -1).compareTo(b.savedVenuesCount ?? -1),
    _ => _compareDateTime(
      a.sortableCreatedAt,
      b.sortableCreatedAt,
      ascending: true,
    ),
  };
}

/// Maps table sort state to the Users filter-bar sort preset label.
String adminUserSortPresetLabel({
  required String sortColumn,
  required bool sortAscending,
}) {
  if (sortColumn == AdminUserTableSortColumn.created && !sortAscending) {
    return 'Newest';
  }
  if (sortColumn == AdminUserTableSortColumn.created && sortAscending) {
    return 'Oldest';
  }
  if (sortColumn == AdminUserTableSortColumn.name) return 'Name';
  if (sortColumn == AdminUserTableSortColumn.lastLogin) return 'Last active';
  return 'Newest';
}

void applyAdminUserSortPreset(
  String preset,
  void Function(String, bool) apply,
) {
  switch (preset) {
    case 'Oldest':
      apply(AdminUserTableSortColumn.created, true);
    case 'Name':
      apply(AdminUserTableSortColumn.name, true);
    case 'Last active':
      apply(AdminUserTableSortColumn.lastLogin, false);
    case 'Newest':
    default:
      apply(AdminUserTableSortColumn.created, false);
  }
}

int _compareDateTime(
  DateTime? left,
  DateTime? right, {
  required bool ascending,
}) {
  if (left == null && right == null) return 0;
  if (left == null) return ascending ? 1 : -1;
  if (right == null) return ascending ? -1 : 1;
  return ascending ? left.compareTo(right) : right.compareTo(left);
}

Set<String> collectUserCities(List<AdminDocumentRow> rows) {
  final cities = <String>{};
  for (final row in rows) {
    final city = AdminUserCrmView(row: row).city.trim();
    if (city.isNotEmpty && city != '—') cities.add(city);
  }
  return cities;
}

Set<String> collectUserRoles(List<AdminDocumentRow> rows) {
  final roles = <String>{};
  for (final row in rows) {
    final role = AdminUserCrmView(row: row).role.trim();
    if (role.isNotEmpty && role != '—') roles.add(role);
  }
  return roles;
}

int countActiveStaffAdminUsers(List<AdminDocumentRow> rows) {
  return rows
      .map((row) => AdminUserCrmView(row: row))
      .where((user) => !user.isDeleted && user.isStaffAdminRole)
      .length;
}

Set<String> collectUserAccountTypes(List<AdminDocumentRow> rows) {
  final types = <String>{};
  for (final row in rows) {
    final label = AdminUserCrmView(row: row).accountTypeLabel.trim();
    if (label.isNotEmpty && label != '—') types.add(label);
  }
  return types;
}
