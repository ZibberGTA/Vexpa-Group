import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_core/entitlements/entitlements.dart';

import '../../venue_management/models/media_library_tab.dart';
import '../../venue_management/models/media_subscription_limits.dart';
import '../data/admin_venue_health_support.dart';
import '../permissions/admin_permission_constants.dart';
import '../permissions/permission_service.dart';
import '../permissions/staff_permission.dart';
import 'admin_dashboard_models.dart';

const kAdminVenueBackendRequiredTooltip = 'Requires backend function.';

enum AdminVenueCrmAction {
  viewProfile,
  editVenue,
  verify,
  unverify,
  hideVenue,
  showVenue,
  openPublicVenue,
  openOnMap,
  suspend,
  unsuspend,
  deleteVenue,
}

/// Sortable venue table column keys.
abstract final class AdminVenueTableSortColumn {
  static const name = 'name';
  static const category = 'category';
  static const city = 'city';
  static const owner = 'owner';
  static const photos = 'photos';
  static const plan = 'plan';
  static const claimStatus = 'claimStatus';
  static const verified = 'verified';
  static const visibility = 'visibility';
  static const healthScore = 'healthScore';
  static const updated = 'updated';
  static const created = 'created';

  static const defaultColumn = created;
  static const defaultAscending = false;
}

class AdminVenueCrmPermissions {
  AdminVenueCrmPermissions(this.permissions);

  final PermissionService permissions;

  bool canViewProfile() => permissions.has(StaffPermission.venuesView);

  bool canEditVenue() => permissions.has(StaffPermission.venuesEdit);

  bool canVerify() => permissions.has(StaffPermission.venueApprove);

  bool canSuspend() => permissions.has(StaffPermission.venuesDelete);

  bool canDelete() => permissions.has(StaffPermission.venuesDelete);

  bool canOpenMap() => permissions.has(StaffPermission.adminMapView);

  bool canHideVenue() => permissions.has(StaffPermission.venuesEdit);

  bool isActionAllowed(AdminVenueCrmAction action) {
    return switch (action) {
      AdminVenueCrmAction.viewProfile => canViewProfile(),
      AdminVenueCrmAction.editVenue => canEditVenue(),
      AdminVenueCrmAction.verify || AdminVenueCrmAction.unverify => canVerify(),
      AdminVenueCrmAction.hideVenue ||
      AdminVenueCrmAction.showVenue => canHideVenue(),
      AdminVenueCrmAction.openPublicVenue => canViewProfile(),
      AdminVenueCrmAction.openOnMap => canOpenMap(),
      AdminVenueCrmAction.suspend ||
      AdminVenueCrmAction.unsuspend => canSuspend(),
      AdminVenueCrmAction.deleteVenue => canDelete(),
    };
  }

  String tooltipFor(AdminVenueCrmAction action, {required bool isBackendTodo}) {
    if (isBackendTodo) return kAdminVenueBackendRequiredTooltip;
    if (isActionAllowed(action)) {
      return switch (action) {
        AdminVenueCrmAction.viewProfile => 'View / Manage venue',
        AdminVenueCrmAction.editVenue => 'Edit venue',
        AdminVenueCrmAction.verify => 'Verify venue',
        AdminVenueCrmAction.unverify => 'Unverify venue',
        AdminVenueCrmAction.hideVenue => 'Hide venue from public',
        AdminVenueCrmAction.showVenue => 'Publish venue / Show publicly',
        AdminVenueCrmAction.openPublicVenue => 'View public venue page',
        AdminVenueCrmAction.openOnMap => 'View on map',
        AdminVenueCrmAction.suspend => 'Disable venue listing',
        AdminVenueCrmAction.unsuspend => 'Enable venue listing',
        AdminVenueCrmAction.deleteVenue =>
          'Delete venue (archives to deleted_venues)',
      };
    }
    return kAdminPermissionDeniedTooltip;
  }

  String? menuSubtitleFor(
    AdminVenueCrmAction action, {
    required bool backendTodo,
  }) {
    if (backendTodo) return kAdminVenueBackendRequiredTooltip;
    if (!isActionAllowed(action)) return 'You do not have permission';
    return null;
  }
}

class AdminVenueCrmView {
  const AdminVenueCrmView({required this.row});

  final AdminDocumentRow row;

  String get venueId => row.id;

  String get name =>
      row.readString(['name', 'venueName'], fallback: 'Unnamed venue');

  String get category => row.readString(['category', 'venueType']);

  String get description =>
      row.readString(['description', 'Description'], fallback: '—');

  String get address => row.readString(['address', 'streetAddress']);

  String get city => row.readString(['city', 'area']);

  String get postcode => row.readString(['postcode', 'postCode', 'zip']);

  String get phone => row.readString(['phone', 'phoneNumber']);

  String get website => row.readString(['website', 'websiteUrl']);

  String get ownerId => row.readString(['ownerId', 'ownerUID']);

  String get ownerName => row.readString(['ownerName']);

  String get claimStatus => row.readString([
    'claimStatus',
    'claimedStatus',
    'claim_state',
  ], fallback: 'unclaimed');

  String get claimStatusLabel {
    final value = claimStatus;
    if (value.isEmpty || value == '—') return 'Unclaimed';
    return value[0].toUpperCase() + value.substring(1);
  }

  bool get isVerified => row.readBool(['isVerified', 'verified']);

  String get verifiedLabel => isVerified ? 'Verified' : 'Unverified';

  bool get isVisible {
    if (row.data['isVisible'] == false) return false;
    if (row.data['publicVisible'] == false) return false;
    if (row.data['isHidden'] == true) return false;
    return true;
  }

  String get visibilityLabel => isVisible ? 'Visible' : 'Hidden';

  String get status {
    final raw = row
        .readString(['status', 'moderationStatus'], fallback: '')
        .trim()
        .toLowerCase();
    if (raw.isNotEmpty && raw != '—') return raw;
    return 'active';
  }

  String get statusLabel {
    final value = status;
    if (value.isEmpty) return 'Active';
    return value[0].toUpperCase() + value.substring(1);
  }

  bool get isSuspended => status == 'suspended';

  bool get isDeleted => row.data['isDeleted'] == true || status == 'deleted';

  bool get isClaimed {
    final owner = ownerId;
    if (owner.isNotEmpty && owner != '—') return true;
    final claim = claimStatus.toLowerCase();
    return claim == 'claimed' || claim == 'approved';
  }

  String get claimedLabel => isClaimed ? 'Claimed' : 'Unclaimed';

  String get logoUrl =>
      row.readString(['logoUrl', 'logoImageUrl', 'venueLogoUrl']);

  String get bannerUrl =>
      row.readString(['bannerImageUrl', 'bannerUrl', 'coverImageUrl']);

  String get subscriptionTier =>
      row.readString(['subscriptionPlanId', 'subscriptionPlan', 'plan']);

  String get subscriptionStatus => row.readString([
    'subscriptionStatus',
    'subscriptionState',
    'billingStatus',
  ]);

  String get createdAt => readDate(const ['createdAt', 'created_at']);

  String get updatedAt => readDate(const ['updatedAt', 'updated_at']);

  int get galleryImagesCount {
    final urls = row.data['galleryImageUrls'] ?? row.data['galleryImages'];
    if (urls is List) return urls.length;
    final count =
        row.data['galleryImagesCount'] ?? row.data['galleryPhotoCount'];
    if (count is num) return count.toInt();
    return 0;
  }

  Map<String, int> get customMediaLimits {
    final raw = row.data['mediaLimits'] ?? row.data['customMediaLimits'];
    if (raw is! Map) return const {};

    final limits = <String, int>{};
    raw.forEach((key, value) {
      if (value is num) limits[key.toString()] = value.toInt();
    });
    return limits;
  }

  String get subscriptionPlanRaw {
    final raw = row.readString([
      'subscriptionPlanId',
      'subscriptionPlan',
      'plan',
      'planId',
    ], fallback: '');
    if (raw.isEmpty || raw == '—') return '';
    return raw.trim().toLowerCase();
  }

  int? get galleryPhotoStorageLimit {
    final planId = subscriptionPlanRaw;
    if (planId.isEmpty) return null;

    final limit = MediaSubscriptionLimits.limitFor(
      planId: planId,
      tab: MediaLibraryTab.venueGallery,
      customLimits: customMediaLimits,
    );
    if (limit <= 0) return null;
    return limit;
  }

  String get photosUsedLabel {
    final count = galleryImagesCount;
    final limit = galleryPhotoStorageLimit;
    if (limit != null) return '$count / $limit photos';
    return '$count photos';
  }

  String get subscriptionPlanPillLabel =>
      adminVenueSubscriptionPlanLabel(subscriptionPlanRaw);

  bool get subscriptionPlanIsPremium =>
      isPremiumVenueSubscriptionTier(subscriptionPlanPillLabel);

  String get ownerDisplayLabel {
    if (ownerName.isNotEmpty && ownerName != '—') return ownerName;
    if (ownerId.isNotEmpty && ownerId != '—') return ownerId;
    return '';
  }

  String get searchBlob => [
    name,
    category,
    city,
    postcode,
    address,
    ownerId,
    ownerName,
    venueId,
  ].join(' ').toLowerCase();

  DateTime? get sortableCreatedAt =>
      readDateTime(const ['createdAt', 'created_at']);

  DateTime? get sortableUpdatedAt =>
      readDateTime(const ['updatedAt', 'updated_at']);

  String readDate(List<String> keys) {
    for (final key in keys) {
      final value = row.data[key];
      if (value == null) continue;
      if (value is Timestamp) return _formatDateTime(value.toDate());
      if (value is DateTime) return _formatDateTime(value);
      if (value is int) {
        final millis = value > 9999999999 ? value : value * 1000;
        return _formatDateTime(
          DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal(),
        );
      }
      if (value is num) {
        final millis = value > 9999999999
            ? value.toInt()
            : (value * 1000).toInt();
        return _formatDateTime(
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

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

}

class AdminVenueHealthItem {
  const AdminVenueHealthItem({required this.label, required this.passed});

  final String label;
  final bool passed;
}

class AdminVenueHealth {
  const AdminVenueHealth({
    required this.scorePercent,
    required this.passedCount,
    required this.totalCount,
    required this.items,
  });

  final int scorePercent;
  final int passedCount;
  final int totalCount;
  final List<AdminVenueHealthItem> items;

  List<AdminVenueHealthItem> get missingItems =>
      items.where((item) => !item.passed).toList(growable: false);

  List<AdminVenueHealthItem> get passedItems =>
      items.where((item) => item.passed).toList(growable: false);

  bool get isComplete => missingItems.isEmpty && totalCount > 0;
}

String formatAdminVenueSubscriptionStatus(String? raw) {
  if (raw == null) return '—';
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '—') return '—';

  return trimmed
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

class AdminVenueContentSummary {
  const AdminVenueContentSummary({
    this.drinksCount,
    this.dealsCount,
    this.eventsCount,
    this.liveDealsCount,
    this.upcomingEventsCount,
    this.galleryImagesCount,
    this.lastContentUpdate,
    this.unavailable = false,
  });

  final int? drinksCount;
  final int? dealsCount;
  final int? eventsCount;
  final int? liveDealsCount;
  final int? upcomingEventsCount;
  final int? galleryImagesCount;
  final String? lastContentUpdate;
  final bool unavailable;
}

class AdminVenueOwnerContext {
  const AdminVenueOwnerContext({
    this.ownerName,
    this.ownerEmail,
    this.ownerStatus,
    this.ownerUid,
    this.subscriptionTier,
    this.subscriptionStatus,
    this.venueLimit,
    this.ownedVenuesCount,
    this.teamMembersCount,
    this.unavailable = false,
  });

  final String? ownerName;
  final String? ownerEmail;
  final String? ownerStatus;
  final String? ownerUid;
  final String? subscriptionTier;
  final String? subscriptionStatus;
  final int? venueLimit;
  final int? ownedVenuesCount;
  final int? teamMembersCount;
  final bool unavailable;
}

class AdminVenueClaimInfo {
  const AdminVenueClaimInfo({
    this.claimStatus,
    this.claimedByUserId,
    this.claimedVenueId,
    this.directorySource,
    this.claimCreatedAt,
    this.claimUpdatedAt,
    this.unavailable = false,
  });

  final String? claimStatus;
  final String? claimedByUserId;
  final String? claimedVenueId;
  final String? directorySource;
  final String? claimCreatedAt;
  final String? claimUpdatedAt;
  final bool unavailable;
}

class AdminVenueSupplementaryData {
  const AdminVenueSupplementaryData({
    required this.content,
    this.owner,
    this.claim,
    required this.reports,
  });

  final AdminVenueContentSummary content;
  final AdminVenueOwnerContext? owner;
  final AdminVenueClaimInfo? claim;
  final List<AdminDocumentRow> reports;
}

List<AdminVenueCrmView> filterAndSortVenues({
  required List<AdminDocumentRow> rows,
  required String search,
  required String claimFilter,
  required String categoryFilter,
  required String cityFilter,
  required String subscriptionFilter,
  required String sortColumn,
  required bool sortAscending,
  Map<String, AdminVenueHealth>? healthByVenueId,
}) {
  final query = search.trim().toLowerCase();
  final filtered = rows.map((row) => AdminVenueCrmView(row: row)).where((
    venue,
  ) {
    if (venue.isDeleted) return false;
    if (claimFilter != 'All') {
      if (claimFilter == 'Claimed' && !venue.isClaimed) return false;
      if (claimFilter == 'Unclaimed' && venue.isClaimed) return false;
    }
    if (categoryFilter != 'All' &&
        venue.category.toLowerCase() != categoryFilter.toLowerCase()) {
      return false;
    }
    if (cityFilter != 'All' &&
        venue.city.toLowerCase() != cityFilter.toLowerCase()) {
      return false;
    }
    if (subscriptionFilter != 'All' &&
        venue.subscriptionPlanPillLabel.toLowerCase() !=
            subscriptionFilter.toLowerCase()) {
      return false;
    }
    if (query.isNotEmpty && !venue.searchBlob.contains(query)) return false;
    return true;
  }).toList();

  filtered.sort((a, b) {
    final result = compareAdminVenueRows(
      a,
      b,
      column: sortColumn,
      healthByVenueId: healthByVenueId,
    );
    return sortAscending ? result : -result;
  });

  return filtered;
}

int compareAdminVenueRows(
  AdminVenueCrmView a,
  AdminVenueCrmView b, {
  required String column,
  Map<String, AdminVenueHealth>? healthByVenueId,
}) {
  return switch (column) {
    AdminVenueTableSortColumn.name => a.name.toLowerCase().compareTo(
      b.name.toLowerCase(),
    ),
    AdminVenueTableSortColumn.category => a.category.toLowerCase().compareTo(
      b.category.toLowerCase(),
    ),
    AdminVenueTableSortColumn.city => a.city.toLowerCase().compareTo(
      b.city.toLowerCase(),
    ),
    AdminVenueTableSortColumn.owner =>
      a.ownerDisplayLabel.toLowerCase().compareTo(
        b.ownerDisplayLabel.toLowerCase(),
      ),
    AdminVenueTableSortColumn.photos => a.galleryImagesCount.compareTo(
      b.galleryImagesCount,
    ),
    AdminVenueTableSortColumn.plan =>
      a.subscriptionPlanPillLabel.toLowerCase().compareTo(
        b.subscriptionPlanPillLabel.toLowerCase(),
      ),
    AdminVenueTableSortColumn.claimStatus =>
      a.isClaimed == b.isClaimed
          ? a.claimedLabel.toLowerCase().compareTo(b.claimedLabel.toLowerCase())
          : a.isClaimed
          ? 1
          : -1,
    AdminVenueTableSortColumn.verified =>
      a.isVerified == b.isVerified
          ? 0
          : a.isVerified
          ? 1
          : -1,
    AdminVenueTableSortColumn.visibility =>
      a.isVisible == b.isVisible
          ? 0
          : a.isVisible
          ? 1
          : -1,
    AdminVenueTableSortColumn.healthScore => _compareHealth(
      healthByVenueId?[a.venueId]?.scorePercent ?? 0,
      healthByVenueId?[b.venueId]?.scorePercent ?? 0,
    ),
    AdminVenueTableSortColumn.updated => _compareDateTime(
      a.sortableUpdatedAt,
      b.sortableUpdatedAt,
    ),
    AdminVenueTableSortColumn.created => _compareDateTime(
      a.sortableCreatedAt,
      b.sortableCreatedAt,
    ),
    _ => _compareDateTime(a.sortableCreatedAt, b.sortableCreatedAt),
  };
}

int _compareDateTime(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int _compareHealth(int a, int b) => a.compareTo(b);

Set<String> collectVenueCategories(List<AdminDocumentRow> rows) {
  final categories = <String>{};
  for (final row in rows) {
    final venue = AdminVenueCrmView(row: row);
    if (venue.category.isNotEmpty && venue.category != '—') {
      categories.add(venue.category);
    }
  }
  return categories;
}

Set<String> collectVenueCities(List<AdminDocumentRow> rows) {
  final cities = <String>{};
  for (final row in rows) {
    final city = AdminVenueCrmView(row: row).city.trim();
    if (city.isNotEmpty && city != '—') cities.add(city);
  }
  return cities;
}

Set<String> collectVenueSubscriptionPlans(List<AdminDocumentRow> rows) {
  final plans = <String>{};
  for (final row in rows) {
    final label = AdminVenueCrmView(row: row).subscriptionPlanPillLabel.trim();
    if (label.isNotEmpty && label != '—' && label != 'Unknown') {
      plans.add(label);
    }
  }
  return plans;
}

const kAdminVenuesCrmPageSizeOptions = [20, 50, 100];

/// Lightweight health score for table display (venue doc only, no counts).
AdminVenueHealth estimateTableHealth(AdminVenueCrmView venue) =>
    AdminVenueHealthSupport.estimateTableHealth(venue);
