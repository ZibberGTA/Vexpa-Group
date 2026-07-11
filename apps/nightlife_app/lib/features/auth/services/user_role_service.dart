import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

enum AppUserRole {
  founder,
  management,
  admin,
  owner,
  employee,
  artist,
  user,
}

extension AppUserRoleX on AppUserRole {
  bool get isStaff =>
      this == AppUserRole.founder ||
      this == AppUserRole.management ||
      this == AppUserRole.admin;

  bool get isBusiness =>
      this == AppUserRole.owner || this == AppUserRole.employee || isStaff;

  /// Venue management tab visibility (owner, employee, or internal staff).
  bool get canManageVenues =>
      this == AppUserRole.owner ||
      this == AppUserRole.employee ||
      isStaff;

  bool get isArtist => this == AppUserRole.artist;

  String get label {
    switch (this) {
      case AppUserRole.founder:
        return 'Founder';
      case AppUserRole.management:
        return 'Management';
      case AppUserRole.admin:
        return 'Admin';
      case AppUserRole.owner:
        return 'Venue Owner';
      case AppUserRole.employee:
        return 'Venue Employee';
      case AppUserRole.artist:
        return 'Artist';
      case AppUserRole.user:
        return 'Customer';
    }
  }
}

/// Cached role resolution snapshot for VexCore identity mapping.
class UserRoleSnapshot {
  const UserRoleSnapshot({
    required this.uid,
    required this.role,
    this.email,
    this.venueIds = const [],
    this.ownedVenuesCount = 0,
    this.roleLevel = 0,
    this.staffFlag = false,
    this.isAdminFlag = false,
    this.source = 'unknown',
  });

  final String uid;
  final String? email;
  final AppUserRole role;
  final List<String> venueIds;
  final int ownedVenuesCount;
  final int roleLevel;
  final bool staffFlag;
  final bool isAdminFlag;
  final String source;
}

/// Firebase Auth session + Firestore `users/{uid}` role resolution.
///
/// Firebase Auth identifies the signed-in user. Role and access are resolved
/// from Firestore (`users/{uid}`) with optional custom-claim staff checks.
/// The `staff/` collection is only queried when permitted — venue owners cannot
/// read `staff/{uid}` per security rules, so user-document resolution is primary.
class UserRoleService {
  UserRoleService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static UserRoleSnapshot? _lastSnapshot;
  static String? _broadcastUid;
  static StreamController<AppUserRole>? _roleBroadcast;
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _usersDocSub;

  static UserRoleSnapshot? peekLastSnapshot(String uid) {
    final snapshot = _lastSnapshot;
    if (snapshot == null || snapshot.uid != uid) return null;
    return snapshot;
  }

  static AppUserRole parseStaffAdminRole({
    required int roleLevel,
    String? rawRole,
  }) {
    if (roleLevel >= 100) return AppUserRole.founder;
    if (roleLevel >= 60) return AppUserRole.management;
    if (roleLevel >= 30) return AppUserRole.admin;
    return parseRole(rawRole ?? 'admin');
  }

  static void _cacheSnapshot(UserRoleSnapshot snapshot) {
    _lastSnapshot = snapshot;
  }

  /// Clears cached identity and shared role stream state — call on logout.
  static Future<void> resetSession() async {
    _lastSnapshot = null;
    _tearDownRoleBroadcast();
  }

  static void _tearDownRoleBroadcast() {
    _broadcastUid = null;
    final sub = _usersDocSub;
    _usersDocSub = null;
    sub?.cancel();
    final controller = _roleBroadcast;
    _roleBroadcast = null;
    controller?.close();
  }

  static AppUserRole parseRole(dynamic value) {
    final role = (value ?? 'user').toString().trim().toLowerCase();

    if (role == 'founder' ||
        role == 'owner_founder' ||
        role == 'app_owner') {
      return AppUserRole.founder;
    }
    if (role == 'management' || role == 'manager') {
      return AppUserRole.management;
    }
    if (role == 'admin') return AppUserRole.admin;
    if (role == 'owner' ||
        role == 'venueowner' ||
        role == 'venue_owner' ||
        role == 'business' ||
        role == 'businessowner' ||
        role == 'business_owner' ||
        role == 'venue') {
      return AppUserRole.owner;
    }
    if (role == 'employee') return AppUserRole.employee;
    if (role == 'artist' || role == 'performer') return AppUserRole.artist;

    return AppUserRole.user;
  }

  static String roleToFirestoreValue(AppUserRole role) {
    switch (role) {
      case AppUserRole.founder:
        return 'founder';
      case AppUserRole.management:
        return 'management';
      case AppUserRole.admin:
        return 'admin';
      case AppUserRole.owner:
        return 'owner';
      case AppUserRole.employee:
        return 'employee';
      case AppUserRole.artist:
        return 'artist';
      case AppUserRole.user:
        return 'user';
    }
  }

  static List<String> _parseVenueIds(Map<String, dynamic>? data) {
    return RoleResolver.parseVenueIds(data?['venueIds']);
  }

  static String? _readRoleField(Map<String, dynamic>? data) {
    return RoleResolver.readRoleField(data);
  }

  static AppUserRole _roleFromStaffData(Map<String, dynamic>? data) {
    if (data == null) return AppUserRole.user;

    final staffResolution = RoleResolver.resolveStaffFromDocument(
      data,
      source: 'staffCollection',
    );
    if (staffResolution != null) {
      return parseStaffAdminRole(
        roleLevel: staffResolution.roleLevel,
        rawRole: RoleResolver.readRoleField(data),
      );
    }

    return parseRole(data['role']);
  }

  static AppUserRole _roleFromCustomClaims(Map<String, dynamic> claims) {
    final staffResolution = RoleResolver.resolveStaffFromClaims(claims);
    if (staffResolution != null) {
      return parseStaffAdminRole(
        roleLevel: staffResolution.roleLevel,
        rawRole: (claims['staffRole'] ?? claims['role'])?.toString(),
      );
    }

    return AppUserRole.user;
  }

  static Future<AppUserRole?> _getStaffRoleFromFirestore(User user) async {
    final staffPath = 'staff/${user.uid}';
    if (kDebugMode) {
      debugPrint('[UserRoleService] staff doc path=$staffPath');
    }

    try {
      final staffByUid = await _db.collection('staff').doc(user.uid).get();
      if (kDebugMode) {
        debugPrint('[UserRoleService] staff doc found=${staffByUid.exists}');
      }
      if (staffByUid.exists) {
        final role = _roleFromStaffData(staffByUid.data());
        if (role.isStaff) return role;
      }

      final email = user.email?.trim().toLowerCase();
      if (email != null && email.isNotEmpty) {
        final staffByEmail = await _db
            .collection('staff')
            .where('emailLower', isEqualTo: email)
            .limit(1)
            .get();

        if (staffByEmail.docs.isNotEmpty) {
          final role = _roleFromStaffData(staffByEmail.docs.first.data());
          if (role.isStaff) return role;
        }

        final legacyStaffByEmail = await _db
            .collection('staff')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (legacyStaffByEmail.docs.isNotEmpty) {
          final role = _roleFromStaffData(legacyStaffByEmail.docs.first.data());
          if (role.isStaff) return role;
        }
      }
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[UserRoleService] staff doc denied/skipped (${error.code}): ${error.message}',
        );
      }
    }

    return null;
  }

  static Future<void> ensureAuthTokenReady(User user) async {
    try {
      await user.getIdToken(true);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[UserRoleService] auth token refresh failed: $error');
      }
    }
  }

  static Future<({Map<String, dynamic>? data, bool found})> _loadUserDocument(
    User user,
  ) async {
    final path = 'users/${user.uid}';
    if (kDebugMode) {
      debugPrint('[UserRoleService] users doc path=$path');
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (attempt > 0) {
          await ensureAuthTokenReady(user);
          if (kDebugMode) {
            debugPrint('[UserRoleService] retrying users doc read after token refresh');
          }
        }

        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (kDebugMode) {
          debugPrint('[UserRoleService] users doc exists=${userDoc.exists}');
          debugPrint(
            '[UserRoleService] raw users role=${userDoc.data()?['role'] ?? '(missing)'}',
          );
        }
        return (data: userDoc.data(), found: userDoc.exists);
      } on FirebaseException catch (error) {
        if (kDebugMode) {
          debugPrint(
            '[UserRoleService] users doc read failed (${error.code}): ${error.message}',
          );
        }
        if (error.code == 'permission-denied' && attempt == 0) {
          continue;
        }
        break;
      }
    }

    return (data: null, found: false);
  }

  static Future<AppUserRole?> _getStaffRoleFromClaims(User user) async {
    try {
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? <String, dynamic>{};
      if (claims['staff'] == true) {
        return _roleFromCustomClaims(claims);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[UserRoleService] custom-claim lookup failed: $error');
      }
    }

    return null;
  }

  static Future<int> _countOwnedVenues(String uid) async {
    try {
      final snapshot = await _db
          .collection('venues')
          .where('ownerId', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .limit(10)
          .get();
      return snapshot.docs.length;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[UserRoleService] owned venues query (with isDeleted) failed (${error.code}) — retrying ownerId only',
        );
      }
      try {
        final snapshot = await _db
            .collection('venues')
            .where('ownerId', isEqualTo: uid)
            .limit(10)
            .get();
        return snapshot.docs
            .where((doc) => doc.data()['isDeleted'] != true)
            .length;
      } catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('[UserRoleService] owned venue lookup failed: $fallbackError');
        }
        return 0;
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[UserRoleService] owned venue lookup failed: $error');
      }
      return 0;
    }
  }

  /// Resolves access from a user document plus venue assignment/ownership signals.
  static AppUserRole resolveFromUserContext({
    required Map<String, dynamic>? data,
    required int venueIdsCount,
    required int ownedVenuesCount,
  }) {
    final dashboardRole = RoleResolver.resolveFromUserContext(
      data: data,
      venueIdsCount: venueIdsCount,
      ownedVenuesCount: ownedVenuesCount,
    );

    return switch (dashboardRole) {
      DashboardRole.venueOwner => AppUserRole.owner,
      DashboardRole.employee => AppUserRole.employee,
      DashboardRole.regularUser => AppUserRole.user,
      DashboardRole.admin => parseStaffAdminRole(
          roleLevel: RoleResolver.readRoleLevel(data?['roleLevel']),
          rawRole: _readRoleField(data),
        ),
    };
  }

  static UserRoleSnapshot _snapshotForResolution({
    required User user,
    required AppUserRole role,
    required Map<String, dynamic>? data,
    required List<String> venueIds,
    required int ownedVenuesCount,
    required String source,
  }) {
    return UserRoleSnapshot(
      uid: user.uid,
      email: user.email,
      role: role,
      venueIds: venueIds,
      ownedVenuesCount: ownedVenuesCount,
      roleLevel: RoleResolver.readRoleLevel(data?['roleLevel']),
      staffFlag: role.isStaff || RoleResolver.readStaffFlag(data),
      isAdminFlag: data?['isAdmin'] == true || role.isStaff,
      source: source,
    );
  }

  static void _logRoleResolution({
    required User user,
    required bool userDocFound,
    required String? roleValue,
    required bool isAdmin,
    required int venueIdsCount,
    required int ownedVenuesCount,
    required AppUserRole resolvedRole,
    String? source,
  }) {
    if (!kDebugMode) return;

    debugPrint('[UserRoleService] auth uid=${user.uid}');
    debugPrint('[UserRoleService] auth email=${user.email ?? '(none)'}');
    debugPrint('[UserRoleService] users doc found=$userDocFound');
    debugPrint('[UserRoleService] raw users role=${roleValue ?? '(missing)'}');
    debugPrint('[UserRoleService] isAdmin=$isAdmin');
    debugPrint('[UserRoleService] venueIds count=$venueIdsCount');
    debugPrint('[UserRoleService] owned venues count=$ownedVenuesCount');
    debugPrint(
      '[UserRoleService] final resolved role=${resolvedRole.name} (${resolvedRole.label})'
      '${source == null ? '' : ' via $source'}',
    );
    debugPrint(
      '[UserRoleService] final access level=${resolvedRole.canManageVenues ? 'venueStaff' : resolvedRole.isStaff ? 'admin' : 'public'}',
    );
  }

  static Future<AppUserRole> resolveRoleForUser(User user) async {
    await ensureAuthTokenReady(user);

    final staffFromClaims = await _getStaffRoleFromClaims(user);
    if (staffFromClaims != null && staffFromClaims.isStaff) {
      _cacheSnapshot(
        _snapshotForResolution(
          user: user,
          role: staffFromClaims,
          data: null,
          venueIds: const [],
          ownedVenuesCount: 0,
          source: 'customClaims',
        ),
      );
      _logRoleResolution(
        user: user,
        userDocFound: false,
        roleValue: null,
        isAdmin: false,
        venueIdsCount: 0,
        ownedVenuesCount: 0,
        resolvedRole: staffFromClaims,
        source: 'customClaims',
      );
      return staffFromClaims;
    }

    final staffFromFirestore = await _getStaffRoleFromFirestore(user);
    if (staffFromFirestore != null && staffFromFirestore.isStaff) {
      _cacheSnapshot(
        _snapshotForResolution(
          user: user,
          role: staffFromFirestore,
          data: null,
          venueIds: const [],
          ownedVenuesCount: 0,
          source: 'staffCollection',
        ),
      );
      _logRoleResolution(
        user: user,
        userDocFound: false,
        roleValue: null,
        isAdmin: false,
        venueIdsCount: 0,
        ownedVenuesCount: 0,
        resolvedRole: staffFromFirestore,
        source: 'staffCollection',
      );
      return staffFromFirestore;
    }

    final userLoad = await _loadUserDocument(user);
    final data = userLoad.data;
    final venueIds = _parseVenueIds(data);
    final ownedVenuesCount = await _countOwnedVenues(user.uid);

    final resolved = resolveFromUserContext(
      data: data,
      venueIdsCount: venueIds.length,
      ownedVenuesCount: ownedVenuesCount,
    );

    _cacheSnapshot(
      _snapshotForResolution(
        user: user,
        role: resolved,
        data: data,
        venueIds: venueIds,
        ownedVenuesCount: ownedVenuesCount,
        source: 'usersCollection',
      ),
    );

    _logRoleResolution(
      user: user,
      userDocFound: userLoad.found,
      roleValue: _readRoleField(data),
      isAdmin: data?['isAdmin'] == true,
      venueIdsCount: venueIds.length,
      ownedVenuesCount: ownedVenuesCount,
      resolvedRole: resolved,
      source: 'usersCollection',
    );

    return resolved;
  }

  static Stream<AppUserRole> _sharedUserRoleStream(User user) {
    if (_broadcastUid == user.uid && _roleBroadcast != null) {
      return _roleBroadcast!.stream;
    }

    _tearDownRoleBroadcast();
    _broadcastUid = user.uid;
    _roleBroadcast = StreamController<AppUserRole>.broadcast();

    Future<void> publish() async {
      final controller = _roleBroadcast;
      if (controller == null || controller.isClosed) return;
      controller.add(await resolveRoleForUserSafely(user));
    }

    publish();
    _usersDocSub = _db.collection('users').doc(user.uid).snapshots().listen(
      (_) => publish(),
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[UserRoleService] users/${user.uid} snapshot error: $error',
          );
          debugPrint('[UserRoleService] continuing role resolution via get()');
        }
        publish();
      },
    );

    return _roleBroadcast!.stream;
  }

  /// Live role stream driven by `users/{uid}` — safe for venue owners.
  ///
  /// Uses one shared Firestore listener per signed-in uid across app surfaces.
  static Stream<AppUserRole> currentUserRoleStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(AppUserRole.user);
    }

    return _sharedUserRoleStream(user);
  }

  /// Safe wrapper — post-login and streams must not throw on role resolution.
  static Future<AppUserRole> resolveRoleForUserSafely(User user) async {
    try {
      return await resolveRoleForUser(user);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[UserRoleService] role resolution failed: $error');
        debugPrint('$stackTrace');
      }

      final ownedVenuesCount = await _countOwnedVenues(user.uid);
      if (ownedVenuesCount > 0) {
        if (kDebugMode) {
          debugPrint(
            '[UserRoleService] auth success uid=${user.uid} fallback=owner via ownedVenuesCount=$ownedVenuesCount',
          );
        }
        return AppUserRole.owner;
      }

      return AppUserRole.user;
    }
  }

  static Future<AppUserRole> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return AppUserRole.user;
    return resolveRoleForUserSafely(user);
  }

  static Future<void> setCurrentUserRole(AppUserRole role) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName,
      'role': roleToFirestoreValue(role),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
