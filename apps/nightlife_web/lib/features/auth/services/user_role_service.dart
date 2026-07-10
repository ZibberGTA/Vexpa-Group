import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/vexcore/identity_mapper.dart';

/// Web-facing roles used for dashboard routing and access control.
enum VexdaUserRole { admin, venueOwner, employee, regularUser }

extension VexdaUserRoleX on VexdaUserRole {
  bool get canAccessAdminDashboard => this == VexdaUserRole.admin;

  bool get canAccessVenueDashboard =>
      this == VexdaUserRole.admin ||
      this == VexdaUserRole.venueOwner ||
      this == VexdaUserRole.employee;

  String get label {
    switch (this) {
      case VexdaUserRole.admin:
        return 'Admin';
      case VexdaUserRole.venueOwner:
        return 'Venue Owner';
      case VexdaUserRole.employee:
        return 'Employee';
      case VexdaUserRole.regularUser:
        return 'Customer';
    }
  }
}

/// Firestore-backed role profile for the signed-in user.
class UserRoleProfile {
  const UserRoleProfile({
    required this.role,
    this.venueIds = const [],
    this.isAdminFlag = false,
    this.ownedVenuesCount = 0,
    this.roleLevel = 0,
    this.staffFlag = false,
    this.source = 'unknown',
  });

  final VexdaUserRole role;
  final List<String> venueIds;
  final bool isAdminFlag;
  final int ownedVenuesCount;
  final int roleLevel;
  final bool staffFlag;
  final String source;

  @override
  bool operator ==(Object other) {
    return other is UserRoleProfile &&
        other.role == role &&
        other.isAdminFlag == isAdminFlag &&
        other.ownedVenuesCount == ownedVenuesCount &&
        other.roleLevel == roleLevel &&
        other.staffFlag == staffFlag &&
        other.source == source &&
        _listEquals(other.venueIds, venueIds);
  }

  @override
  int get hashCode => Object.hash(
    role,
    isAdminFlag,
    ownedVenuesCount,
    roleLevel,
    staffFlag,
    source,
    Object.hashAll(venueIds),
  );
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _StaffRoleResolution {
  const _StaffRoleResolution({
    required this.role,
    required this.roleLevel,
    required this.staffFlag,
    required this.source,
  });

  final VexdaUserRole role;
  final int roleLevel;
  final bool staffFlag;
  final String source;
}

/// Reads user roles from Firestore — compatible with the mobile app schema.
///
/// Firebase Auth identifies the signed-in user. Role resolution is driven by
/// `users/{uid}` with optional staff/custom-claim enhancement for admin access.
/// `staff/{uid}` is never required — permission-denied staff reads must not
/// block venue owners from signing in.
class UserRoleService {
  UserRoleService._();

  /// Set to `true` locally when debugging role resolution issues.
  static const bool debugRoleResolution = true;

  /// Temporary transition logs for diagnosing resolver stalls (debug builds only).
  static const bool debugRoleTransition = true;

  static String? _activeUid;
  static StreamController<UserRoleProfile>? _profileBroadcast;
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _usersDocSub;
  static String? _profileStreamUid;
  static User? _profileStreamUser;
  static Timer? _profileDebounce;
  static bool _profilePublishInFlight = false;
  static bool _profilePublishScheduled = false;
  static Future<void>? _usersDocBindInFlight;
  static UserRoleProfile? _cachedProfile;
  static String? _cachedProfileUid;
  static Future<UserRoleProfile>? _resolveInFlight;
  static String? _resolveInFlightUid;

  static FirebaseAuth? get _auth {
    if (!VexdaFirebase.isReady) return null;
    return FirebaseAuth.instance;
  }

  static FirebaseFirestore? get _db {
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  static void _log(String message) {
    if (kDebugMode && debugRoleResolution) {
      debugPrint('[UserRoleService] $message');
    }
  }

  static void _logTransition(String message) {
    if (kDebugMode && debugRoleTransition) {
      debugPrint('[UserRoleService] $message');
    }
  }

  static void debugLogAccessDecision({
    required String uid,
    required UserRoleProfile profile,
    required bool canAccessAdminDashboard,
  }) {
    if (!kDebugMode || !debugRoleTransition) return;

    _logTransition(
      'access decision uid=$uid resolvedRole=${profile.role.name} '
      'roleLevel=${profile.roleLevel} staff=${profile.staffFlag} '
      'source=${profile.source} '
      'canAccessAdminDashboard=$canAccessAdminDashboard',
    );
  }

  static String? _lastDashboardVisibilityLogKey;

  static void debugLogDashboardButtonVisibility({
    required String uid,
    required bool visible,
    required VexdaUserRole role,
  }) {
    if (!kDebugMode || !debugRoleTransition) return;

    final key = '$uid|$visible|${role.name}';
    if (_lastDashboardVisibilityLogKey == key) return;
    _lastDashboardVisibilityLogKey = key;

    _logTransition(
      'dashboard button visible=$visible uid=$uid role=${role.name}',
    );
  }

  /// Clears cached profiles and stream listeners — call on logout.
  static Future<void> clearSessionCache() async {
    _profileDebounce?.cancel();
    _profileDebounce = null;

    final sub = _usersDocSub;
    _usersDocSub = null;
    if (sub != null) {
      await sub.cancel();
    }

    final controller = _profileBroadcast;
    _profileBroadcast = null;
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    _profileStreamUid = null;
    _profileStreamUser = null;
    _activeUid = null;
    _cachedProfile = null;
    _cachedProfileUid = null;
    _resolveInFlight = null;
    _resolveInFlightUid = null;
    _lastDashboardVisibilityLogKey = null;
    _usersDocBindInFlight = null;
  }

  @visibleForTesting
  static Future<void> debugResetSessionCache() => clearSessionCache();

  @visibleForTesting
  static bool safeStreamAdd<T>(StreamController<T> controller, T event) {
    if (controller.isClosed) return false;
    try {
      controller.add(event);
      return true;
    } on StateError {
      return false;
    }
  }

  static List<String> _parseVenueIds(dynamic value) =>
      RoleResolver.parseVenueIds(value);

  static String? _readRoleField(Map<String, dynamic>? data) =>
      RoleResolver.readRoleField(data);

  static int _readRoleLevel(dynamic value) => RoleResolver.readRoleLevel(value);

  static bool _readStaffFlag(Map<String, dynamic>? data) =>
      RoleResolver.readStaffFlag(data);

  /// True when a `staff/{uid}` document grants admin/staff dashboard access.
  @visibleForTesting
  static bool isValidStaffDocument(Map<String, dynamic>? data) =>
      RoleResolver.isValidStaffDocument(data);

  static _StaffRoleResolution? _staffResolutionFromDocument(
    Map<String, dynamic> data, {
    required String source,
  }) {
    final resolution = RoleResolver.resolveStaffFromDocument(
      data,
      source: source,
    );
    if (resolution == null) return null;

    return _StaffRoleResolution(
      role: vexdaRoleFromDashboard(resolution.dashboardRole),
      roleLevel: resolution.roleLevel,
      staffFlag: resolution.staffFlag,
      source: resolution.source,
    );
  }

  /// Parses `users/{uid}.role` plus optional `isAdmin` and `venueIds`.
  ///
  /// Does not check owned venues — use [resolveFromUserContext] for full access.
  static VexdaUserRole parseUserDocument(Map<String, dynamic>? data) {
    return vexdaRoleFromDashboard(RoleResolver.parseUserDocument(data));
  }

  static VexdaUserRole resolveFromUserContext({
    required Map<String, dynamic>? data,
    required int venueIdsCount,
    required int ownedVenuesCount,
  }) {
    return vexdaRoleFromDashboard(
      RoleResolver.resolveFromUserContext(
        data: data,
        venueIdsCount: venueIdsCount,
        ownedVenuesCount: ownedVenuesCount,
      ),
    );
  }

  static Future<void> ensureAuthTokenReady(User user) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await user.getIdToken(attempt > 0);
        return;
      } catch (error) {
        _log('auth token refresh failed (attempt ${attempt + 1}): $error');
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 150 * (attempt + 1)),
          );
        }
      }
    }
  }

  static Future<({Map<String, dynamic>? data, bool found})> _loadUserDocument(
    FirebaseFirestore db,
    User user,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (attempt > 0) {
          await ensureAuthTokenReady(user);
          _log('retrying users doc read after token refresh');
          await Future<void>.delayed(Duration(milliseconds: 100 * attempt));
        }

        final userDoc = await db.collection('users').doc(user.uid).get();
        _log(
          'users/${user.uid} exists=${userDoc.exists} role=${userDoc.data()?['role'] ?? '(missing)'}',
        );
        return (data: userDoc.data(), found: userDoc.exists);
      } on FirebaseException catch (error) {
        _log('users doc read failed (${error.code}): ${error.message}');
        if (error.code == 'permission-denied' && attempt < 2) {
          continue;
        }
        break;
      }
    }

    return (data: null, found: false);
  }

  static Future<_StaffRoleResolution?> _getStaffRoleFromClaims(
    User user,
  ) async {
    try {
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? <String, dynamic>{};
      final roleLevel = _readRoleLevel(claims['roleLevel']);
      final staffFlag = claims['staff'] == true;
      final staffRole = (claims['staffRole'] ?? claims['role'] ?? '')
          .toString()
          .trim();

      _logTransition(
        'custom claims uid=${user.uid} role=$staffRole roleLevel=$roleLevel '
        'staff=$staffFlag',
      );

      final coreResolution = RoleResolver.resolveStaffFromClaims(claims);
      if (coreResolution == null) return null;

      return _StaffRoleResolution(
        role: vexdaRoleFromDashboard(coreResolution.dashboardRole),
        roleLevel: coreResolution.roleLevel,
        staffFlag: coreResolution.staffFlag,
        source: coreResolution.source,
      );
    } catch (error) {
      _logTransition('custom-claim lookup failed uid=${user.uid} error=$error');
    }

    return null;
  }

  static void _logStaffDocumentSnapshot({
    required User user,
    required String staffDocPath,
    required bool exists,
    Map<String, dynamic>? data,
  }) {
    final roleValue = data?['role']?.toString();
    final roleLevel = _readRoleLevel(data?['roleLevel']);
    final staffFlag = _readStaffFlag(data);

    _logTransition(
      'staff doc exists=$exists uid=${user.uid} path=$staffDocPath '
      'role=$roleValue roleLevel=$roleLevel staff=$staffFlag',
    );
  }

  /// Reads `staff/{uid}` first, then optional email fallbacks.
  static Future<_StaffRoleResolution?> _getStaffRoleFromFirestore(
    User user,
  ) async {
    final db = _db;
    if (db == null) {
      _logTransition(
        'staff lookup skipped firestore unavailable uid=${user.uid}',
      );
      return null;
    }

    final staffDocPath = 'staff/${user.uid}';
    _logTransition(
      'attempting staff doc read path=$staffDocPath uid=${user.uid}',
    );

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (attempt > 0) {
          await ensureAuthTokenReady(user);
          _logTransition(
            'retrying staff doc read uid=${user.uid} attempt=${attempt + 1}',
          );
          await Future<void>.delayed(Duration(milliseconds: 100 * attempt));
        }

        final staffByUid = await db.collection('staff').doc(user.uid).get();
        final data = staffByUid.data();
        _logStaffDocumentSnapshot(
          user: user,
          staffDocPath: staffDocPath,
          exists: staffByUid.exists,
          data: data,
        );

        if (staffByUid.exists && data != null) {
          _logTransition(
            'Firestore rules can evaluate hasStaffDocument() for uid=${user.uid}',
          );
          final resolution = _staffResolutionFromDocument(
            data,
            source: 'staffCollection',
          );
          if (resolution != null) {
            return resolution;
          }

          _logTransition(
            'staff doc present but not admin-eligible uid=${user.uid}',
          );
          return null;
        }

        _logTransition(
          'staff doc missing at required path=$staffDocPath — '
          'Firestore rules hasStaffDocument() will be false',
        );

        break;
      } on FirebaseException catch (error) {
        _logTransition(
          'staff doc read failed uid=${user.uid} attempt=${attempt + 1} '
          'code=${error.code} message=${error.message}',
        );
        if (error.code == 'permission-denied' && attempt < 2) {
          continue;
        }
        return null;
      }
    }

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      _logTransition('no staff doc and no email fallback uid=${user.uid}');
      return null;
    }

    try {
      final staffByEmail = await db
          .collection('staff')
          .where('emailLower', isEqualTo: email)
          .limit(1)
          .get();

      if (staffByEmail.docs.isNotEmpty) {
        return _staffResolutionFromEmailFallback(
          user: user,
          doc: staffByEmail.docs.first,
          lookup: 'emailLower',
        );
      }

      final legacyStaffByEmail = await db
          .collection('staff')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (legacyStaffByEmail.docs.isNotEmpty) {
        return _staffResolutionFromEmailFallback(
          user: user,
          doc: legacyStaffByEmail.docs.first,
          lookup: 'email',
        );
      }
    } on FirebaseException catch (error) {
      _logTransition(
        'staff email lookup failed uid=${user.uid} '
        'code=${error.code} message=${error.message}',
      );
    }

    _logTransition('no valid staff document uid=${user.uid}');
    return null;
  }

  static _StaffRoleResolution? _staffResolutionFromEmailFallback({
    required User user,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String lookup,
  }) {
    final data = doc.data();
    final foundPath = doc.reference.path;
    final expectedPath = 'staff/${user.uid}';

    _logTransition(
      'staff email lookup via $lookup foundPath=$foundPath expectedPath=$expectedPath',
    );

    final resolution = _staffResolutionFromDocument(
      data,
      source: 'staffCollectionEmailFallback',
    );
    if (resolution == null) return null;

    if (doc.id != user.uid) {
      _logTransition(
        'WARNING: admin resolved via email fallback only. '
        'Firestore rules will not recognise this user unless staff/${user.uid} exists. '
        'foundDocId=${doc.id} authUid=${user.uid}',
      );
    }

    return resolution;
  }

  static Future<int> _countOwnedVenues(String uid) async {
    final db = _db;
    if (db == null) return 0;

    try {
      final snapshot = await db
          .collection('venues')
          .where('ownerId', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .limit(10)
          .get();
      return snapshot.docs.length;
    } on FirebaseException catch (error) {
      _log(
        'owned venues query (with isDeleted) failed (${error.code}) — retrying ownerId only',
      );
      try {
        final snapshot = await db
            .collection('venues')
            .where('ownerId', isEqualTo: uid)
            .limit(10)
            .get();
        return snapshot.docs
            .where((doc) => doc.data()['isDeleted'] != true)
            .length;
      } catch (fallbackError) {
        _log('owned venue lookup failed: $fallbackError');
        return 0;
      }
    } catch (error) {
      _log('owned venue lookup failed: $error');
      return 0;
    }
  }

  static void _logRoleResolution({
    required User user,
    required VexdaUserRole resolvedRole,
    String? source,
    String? targetRoute,
  }) {
    if (!debugRoleResolution) return;

    _log(
      'uid=${user.uid} role=${resolvedRole.name} (${resolvedRole.label})'
      '${source == null ? '' : ' via $source'}'
      '${targetRoute == null ? '' : ' -> $targetRoute'}',
    );
  }

  static void _storeCachedProfile(String uid, UserRoleProfile profile) {
    _cachedProfileUid = uid;
    _cachedProfile = profile;
    if (_activeUid == null || _activeUid == uid) {
      _activeUid = uid;
    }
  }

  /// Synchronous read of the last completed profile for [uid], if any.
  static UserRoleProfile? peekCachedProfile(String uid) {
    if (_cachedProfileUid == uid && _cachedProfile != null) {
      return _cachedProfile;
    }
    return null;
  }

  @visibleForTesting
  static UserRoleProfile? get debugCachedProfile => _cachedProfile;

  @visibleForTesting
  static bool debugWouldDowngradeRole(
    VexdaUserRole current,
    VexdaUserRole next,
  ) {
    return _wouldDowngradeRole(current, next);
  }

  @visibleForTesting
  static void debugPrepareActiveUid(String uid) {
    if (_activeUid != null && _activeUid != uid) {
      unawaited(clearSessionCache());
    }
    _activeUid = uid;
  }

  @visibleForTesting
  static String? get debugActiveUid => _activeUid;

  static bool _wouldDowngradeRole(VexdaUserRole current, VexdaUserRole next) {
    return RoleResolver.wouldDowngradeRole(
      dashboardRoleFromVexda(current),
      dashboardRoleFromVexda(next),
    );
  }

  static void _invalidateResolvedProfileCache() {
    _cachedProfile = null;
    _cachedProfileUid = null;
    _resolveInFlight = null;
    _resolveInFlightUid = null;
  }

  @visibleForTesting
  static Future<UserRoleProfile> debugDedupeResolve(
    String uid,
    Future<UserRoleProfile> Function() loader,
  ) {
    if (_cachedProfileUid == uid && _cachedProfile != null) {
      return Future.value(_cachedProfile!);
    }

    if (_resolveInFlightUid == uid && _resolveInFlight != null) {
      return _resolveInFlight!;
    }

    _resolveInFlightUid = uid;
    _resolveInFlight = loader()
        .then((profile) {
          _storeCachedProfile(uid, profile);
          return profile;
        })
        .whenComplete(() {
          if (_resolveInFlightUid == uid) {
            _resolveInFlight = null;
            _resolveInFlightUid = null;
          }
        });

    return _resolveInFlight!;
  }

  @visibleForTesting
  static void debugSeedProfile(String uid, UserRoleProfile profile) {
    _storeCachedProfile(uid, profile);
  }

  @visibleForTesting
  static Stream<UserRoleProfile> debugSeededProfileStream(String uid) {
    late final StreamController<UserRoleProfile> controller;
    controller = StreamController<UserRoleProfile>.broadcast(
      onListen: () {
        final cached = _cachedProfileUid == uid ? _cachedProfile : null;
        if (cached != null) {
          safeStreamAdd(controller, cached);
        }
      },
    );
    return controller.stream;
  }

  static Future<UserRoleProfile> _resolveProfileForUserDeduped(
    User user,
  ) async {
    return debugDedupeResolve(
      user.uid,
      () => resolveProfileForUserSafely(user),
    );
  }

  static UserRoleProfile _profileFromStaffResolution(
    _StaffRoleResolution staff,
  ) {
    return UserRoleProfile(
      role: VexdaUserRole.admin,
      isAdminFlag: true,
      roleLevel: staff.roleLevel,
      staffFlag: staff.staffFlag,
      source: staff.source,
    );
  }

  static Future<UserRoleProfile> resolveProfileForUser(User user) async {
    _logTransition('role resolution started uid=${user.uid}');
    await ensureAuthTokenReady(user);

    // Staff collection always wins over users/{uid}.
    final staffFromFirestore = await _getStaffRoleFromFirestore(user);
    if (staffFromFirestore != null) {
      final profile = _profileFromStaffResolution(staffFromFirestore);
      if (staffFromFirestore.source == 'staffCollectionEmailFallback') {
        _logTransition(
          'WARNING: final role uses email fallback source only — '
          'create staff/${user.uid} so Firestore rules grant admin reads',
        );
      }
      _logRoleResolution(
        user: user,
        resolvedRole: profile.role,
        source: staffFromFirestore.source,
      );
      _logTransition(
        'final role emitted ${profile.role.name} via ${staffFromFirestore.source} '
        'canAccessAdminDashboard=${profile.role.canAccessAdminDashboard}',
      );
      return profile;
    }

    final staffFromClaims = await _getStaffRoleFromClaims(user);
    if (staffFromClaims != null) {
      final profile = _profileFromStaffResolution(staffFromClaims);
      _logRoleResolution(
        user: user,
        resolvedRole: profile.role,
        source: staffFromClaims.source,
      );
      _logTransition(
        'final role emitted ${profile.role.name} via ${staffFromClaims.source} '
        'canAccessAdminDashboard=${profile.role.canAccessAdminDashboard}',
      );
      return profile;
    }

    final db = _db;
    if (db == null) {
      _log('Firestore unavailable — defaulting to regularUser');
      _logTransition('final role emitted regularUser (firestore unavailable)');
      return const UserRoleProfile(role: VexdaUserRole.regularUser);
    }

    final userLoad = await _loadUserDocument(db, user);
    final data = userLoad.data;
    final roleValue = _readRoleField(data);
    final roleLevel = _readRoleLevel(data?['roleLevel']);
    final staffFlag = _readStaffFlag(data);
    _logTransition(
      'users doc role uid=${user.uid} role=${roleValue ?? '(missing)'} '
      'roleLevel=$roleLevel staff=$staffFlag',
    );

    final venueIds = _parseVenueIds(data?['venueIds']);
    final ownedVenuesCount = await _countOwnedVenues(user.uid);
    if (ownedVenuesCount > 0) {
      _logTransition(
        'owner venue count found uid=${user.uid} count=$ownedVenuesCount',
      );
    }

    final resolvedRole = resolveFromUserContext(
      data: data,
      venueIdsCount: venueIds.length,
      ownedVenuesCount: ownedVenuesCount,
    );

    _logRoleResolution(
      user: user,
      resolvedRole: resolvedRole,
      source: 'usersCollection',
    );
    _logTransition(
      'final role emitted ${resolvedRole.name} via usersCollection '
      'canAccessAdminDashboard=${resolvedRole.canAccessAdminDashboard}',
    );

    return UserRoleProfile(
      role: resolvedRole,
      venueIds: venueIds,
      isAdminFlag:
          data?['isAdmin'] == true || resolvedRole == VexdaUserRole.admin,
      ownedVenuesCount: ownedVenuesCount,
      roleLevel: roleLevel,
      staffFlag: staffFlag,
      source: 'usersCollection',
    );
  }

  static void _ensureProfileStream(User user) {
    if (_profileBroadcast != null && _profileStreamUid == user.uid) {
      return;
    }

    final oldController = _profileBroadcast;
    _profileStreamUid = user.uid;
    _profileStreamUser = user;
    _activeUid = user.uid;

    _profileBroadcast = StreamController<UserRoleProfile>.broadcast(
      onListen: () => _replayCachedProfile(user.uid),
    );

    if (oldController != null && !oldController.isClosed) {
      unawaited(oldController.close());
    }

    unawaited(_bindUsersDocListener(user));
  }

  static void _replayCachedProfile(String uid) {
    final controller = _profileBroadcast;
    if (controller == null || controller.isClosed) return;

    final cached = peekCachedProfile(uid);
    if (cached != null) {
      safeStreamAdd(controller, cached);
      return;
    }

    final user = _profileStreamUser;
    if (user != null && user.uid == uid) {
      unawaited(_publishProfileUpdate(user, immediate: true));
    }
  }

  static Future<void> _bindUsersDocListener(User user) async {
    if (_usersDocSub != null && _profileStreamUid == user.uid) {
      return;
    }

    if (_usersDocBindInFlight != null) {
      await _usersDocBindInFlight;
      return;
    }

    _usersDocBindInFlight = _bindUsersDocListenerImpl(user);
    try {
      await _usersDocBindInFlight;
    } finally {
      _usersDocBindInFlight = null;
    }
  }

  static Future<void> _bindUsersDocListenerImpl(User user) async {
    if (_profileStreamUid != user.uid) return;

    final existing = _usersDocSub;
    _usersDocSub = null;
    if (existing != null) {
      await existing.cancel();
    }

    if (_profileStreamUid != user.uid) return;

    final db = _db;
    if (db == null) return;

    _usersDocSub = db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (_) => _scheduleProfilePublish(user),
          onError: (Object error, StackTrace stackTrace) {
            _log('users/${user.uid} snapshot error: $error');
            _scheduleProfilePublish(user);
          },
        );

    if (peekCachedProfile(user.uid) == null) {
      await _publishProfileUpdate(user, immediate: true);
    }
  }

  static void _scheduleProfilePublish(User user, {bool immediate = false}) {
    if (_profileBroadcast == null ||
        _profileBroadcast!.isClosed ||
        _profileStreamUid != user.uid) {
      return;
    }

    if (immediate) {
      _profileDebounce?.cancel();
      _profileDebounce = null;
      unawaited(_publishProfileUpdate(user, immediate: true));
      return;
    }

    _profileDebounce?.cancel();
    _profileDebounce = Timer(const Duration(milliseconds: 250), () {
      _profileDebounce = null;
      unawaited(_publishProfileUpdate(user));
    });
  }

  static Future<void> _publishProfileUpdate(
    User user, {
    bool immediate = false,
  }) async {
    if (_profileBroadcast == null ||
        _profileBroadcast!.isClosed ||
        _profileStreamUid != user.uid) {
      return;
    }

    if (_profilePublishInFlight) {
      _profilePublishScheduled = true;
      return;
    }

    _profilePublishInFlight = true;
    try {
      final profile = await _resolveProfileForUserDeduped(user);
      if (_profileBroadcast == null ||
          _profileBroadcast!.isClosed ||
          _profileStreamUid != user.uid) {
        return;
      }
      _storeCachedProfile(user.uid, profile);
      safeStreamAdd(_profileBroadcast!, profile);
    } finally {
      _profilePublishInFlight = false;
      if (_profilePublishScheduled &&
          _profileBroadcast != null &&
          !_profileBroadcast!.isClosed &&
          _profileStreamUid == user.uid) {
        _profilePublishScheduled = false;
        await _publishProfileUpdate(user, immediate: immediate);
      }
    }
  }

  /// Publishes a completed profile to active listeners without re-fetching.
  static void _publishResolvedProfile(User user, UserRoleProfile profile) {
    _storeCachedProfile(user.uid, profile);
    _ensureProfileStream(user);
    if (_profileBroadcast != null && !_profileBroadcast!.isClosed) {
      safeStreamAdd(_profileBroadcast!, profile);
    }
  }

  /// Live role stream driven by `users/{uid}` — safe for venue owners.
  ///
  /// Returns a stable broadcast stream per signed-in uid so multiple
  /// [StreamBuilder]s share one Firestore listener.
  static Stream<UserRoleProfile> currentUserProfileStream() {
    final user = _auth?.currentUser;
    if (user == null) {
      unawaited(clearSessionCache());
      return Stream.value(
        const UserRoleProfile(role: VexdaUserRole.regularUser),
      );
    }

    _ensureProfileStream(user);
    return _profileBroadcast!.stream;
  }

  static Stream<VexdaUserRole> currentUserRoleStream() {
    return currentUserProfileStream().map((profile) => profile.role).distinct();
  }

  static Future<UserRoleProfile> getCurrentUserProfile() async {
    final user = _auth?.currentUser;
    if (user == null) {
      return const UserRoleProfile(role: VexdaUserRole.regularUser);
    }

    return _resolveProfileForUserDeduped(user);
  }

  /// Clears pending resolution state, re-resolves, and publishes to listeners.
  static Future<UserRoleProfile> retryRoleResolution(User user) async {
    _invalidateResolvedProfileCache();
    final profile = await _resolveProfileForUserDeduped(user);
    _publishResolvedProfile(user, profile);
    _logTransition('final resolved role ${profile.role.name} uid=${user.uid}');
    return profile;
  }

  static Future<VexdaUserRole> getCurrentUserRole() async {
    final profile = await getCurrentUserProfile();
    return profile.role;
  }

  /// Maps a resolved role to the post-login route.
  static String routeForRole(VexdaUserRole role) {
    return switch (role) {
      VexdaUserRole.admin => AppRouter.admin,
      VexdaUserRole.venueOwner ||
      VexdaUserRole.employee => AppRouter.venueDashboard,
      VexdaUserRole.regularUser => AppRouter.home,
    };
  }

  /// Routes after login or signup — venue owners without venues go to onboarding.
  static String routeAfterAuth(UserRoleProfile profile) {
    if (profile.role == VexdaUserRole.venueOwner &&
        profile.ownedVenuesCount == 0 &&
        profile.venueIds.isEmpty) {
      return AppRouter.businessClaim;
    }
    return routeForRole(profile.role);
  }

  /// Post-login navigation — never throws; auth success must not surface as login failure.
  static Future<PostLoginNavigation> resolvePostLoginNavigation(
    User user,
  ) async {
    _logTransition('login success uid=${user.uid}');
    final profile = await _resolveProfileForUserDeduped(user);
    _publishResolvedProfile(user, profile);
    final route = routeAfterAuth(profile);

    _logRoleResolution(
      user: user,
      resolvedRole: profile.role,
      source: 'postLogin',
      targetRoute: route,
    );
    _logTransition('final resolved role ${profile.role.name} uid=${user.uid}');
    _logTransition('navigation target selected uid=${user.uid} route=$route');

    return PostLoginNavigation(profile: profile, route: route);
  }

  /// Safe wrapper used by streams and post-login routing.
  static Future<UserRoleProfile> resolveProfileForUserSafely(User user) async {
    try {
      return await resolveProfileForUser(user);
    } catch (error, stackTrace) {
      _log('role resolution failed: $error\n$stackTrace');
      _invalidateResolvedProfileCache();

      final ownedVenuesCount = await _countOwnedVenues(user.uid);
      if (ownedVenuesCount > 0) {
        final profile = UserRoleProfile(
          role: VexdaUserRole.venueOwner,
          ownedVenuesCount: ownedVenuesCount,
          source: 'ownedVenuesFallback',
        );
        _logTransition(
          'final role emitted venueOwner via ownedVenues fallback',
        );
        return profile;
      }

      _logTransition('final role emitted regularUser via error fallback');
      return const UserRoleProfile(role: VexdaUserRole.regularUser);
    }
  }
}

/// Result of post-login role resolution and routing.
class PostLoginNavigation {
  const PostLoginNavigation({required this.profile, required this.route});

  final UserRoleProfile profile;
  final String route;

  bool get hasStaffDashboardAccess =>
      profile.role.canAccessVenueDashboard ||
      profile.role.canAccessAdminDashboard;
}
