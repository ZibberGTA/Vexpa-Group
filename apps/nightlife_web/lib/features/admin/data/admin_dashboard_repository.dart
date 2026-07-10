import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/admin_dashboard_models.dart';
import '../models/admin_user_crm.dart';
import '../models/admin_venue_crm.dart';

enum StaffInviteUpsertResult { created, updated, alreadyStaffMember }

/// Firestore access layer for the internal admin platform.
///
/// This repository intentionally reads existing Vexda collections instead of
/// creating admin-specific mirrors. Write helpers update the target document in
/// place; audit logging is left as a TODO until server-side enforcement exists.
class AdminDashboardRepository {
  AdminDashboardRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  Stream<List<AdminDocumentRow>> watchCollection(
    String collectionPath, {
    int limit = 80,
  }) async* {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      yield const [];
      return;
    }

    Query<Map<String, dynamic>> query = firestore.collection(collectionPath);

    if (collectionPath == 'venues' ||
        collectionPath == 'drinks' ||
        collectionPath == 'deals' ||
        collectionPath == 'events') {
      query = query.where('isDeleted', isEqualTo: false);
    }

    yield* query
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AdminDocumentRow(
                  id: doc.id,
                  path: doc.reference.path,
                  data: doc.data(),
                ),
              )
              .toList(),
        );
  }

  Stream<List<AdminDocumentRow>> watchStaffCollection({
    int limit = 500,
  }) async* {
    const collectionPath = 'staff';
    final firestore = _resolveFirestore();
    if (firestore == null) {
      _debugStaffLog(
        'Firebase not ready. collection=$collectionPath path=$collectionPath '
        'completedSuccessfully=false',
      );
      yield const [];
      return;
    }

    final query = firestore.collection(collectionPath).limit(limit);
    _debugStaffLog(
      'Query starting. collection=$collectionPath path=$collectionPath '
      'limit=$limit',
    );

    try {
      var receivedFirstSnapshot = false;
      Timer? diagnosticTimer;

      diagnosticTimer = Timer(const Duration(seconds: 15), () {
        if (!receivedFirstSnapshot) {
          _debugStaffLog(
            'Still waiting for staff snapshot after 15s. '
            'collection=$collectionPath path=$collectionPath '
            'waitingForever=true',
          );
        }
      });

      try {
        await for (final snapshot in query.snapshots()) {
          if (!receivedFirstSnapshot) {
            receivedFirstSnapshot = true;
            diagnosticTimer?.cancel();
            diagnosticTimer = null;
          }
          _debugStaffLog(
            'Query returned. collection=$collectionPath path=$collectionPath '
            'documents=${snapshot.docs.length} completedSuccessfully=true',
          );
          yield snapshot.docs
              .map(
                (doc) => AdminDocumentRow(
                  id: doc.id,
                  path: doc.reference.path,
                  data: doc.data(),
                ),
              )
              .toList(growable: false);
        }
      } finally {
        diagnosticTimer?.cancel();
      }
      _debugStaffLog(
        'Stream completed. collection=$collectionPath path=$collectionPath',
      );
    } on FirebaseException catch (error, stackTrace) {
      _debugStaffLog(
        'FirebaseException. collection=$collectionPath path=$collectionPath '
        'code=${error.code} message=${error.message}',
      );
      if (kDebugMode) debugPrint('$stackTrace');
      rethrow;
    } on Object catch (error, stackTrace) {
      _debugStaffLog(
        'Stream error. collection=$collectionPath path=$collectionPath '
        'error=$error',
      );
      if (kDebugMode) debugPrint('$stackTrace');
      rethrow;
    } finally {
      _debugStaffLog(
        'Stream listener ended or cancelled. collection=$collectionPath '
        'path=$collectionPath',
      );
    }
  }

  Stream<List<AdminDocumentRow>> watchStaffInvitesCollection({
    int limit = 500,
  }) async* {
    const collectionPath = 'staff_invites';
    final firestore = _resolveFirestore();
    if (firestore == null) {
      _debugStaffLog(
        'Firebase not ready. collection=$collectionPath path=$collectionPath '
        'completedSuccessfully=false',
      );
      yield const [];
      return;
    }

    final query = firestore.collection(collectionPath).limit(limit);
    _debugStaffLog(
      'Query starting. collection=$collectionPath path=$collectionPath '
      'limit=$limit',
    );

    try {
      var receivedFirstSnapshot = false;
      Timer? diagnosticTimer;

      diagnosticTimer = Timer(const Duration(seconds: 15), () {
        if (!receivedFirstSnapshot) {
          _debugStaffLog(
            'Still waiting for staff_invites snapshot after 15s. '
            'collection=$collectionPath path=$collectionPath '
            'waitingForever=true',
          );
        }
      });

      try {
        await for (final snapshot in query.snapshots()) {
          if (!receivedFirstSnapshot) {
            receivedFirstSnapshot = true;
            diagnosticTimer?.cancel();
            diagnosticTimer = null;
          }
          _debugStaffLog(
            'Query returned. collection=$collectionPath path=$collectionPath '
            'documents=${snapshot.docs.length} completedSuccessfully=true',
          );
          yield snapshot.docs
              .map(
                (doc) => AdminDocumentRow(
                  id: doc.id,
                  path: doc.reference.path,
                  data: doc.data(),
                ),
              )
              .toList(growable: false);
        }
      } finally {
        diagnosticTimer?.cancel();
      }
    } on FirebaseException catch (error, stackTrace) {
      _debugStaffLog(
        'FirebaseException. collection=$collectionPath path=$collectionPath '
        'code=${error.code} message=${error.message}',
      );
      if (kDebugMode) debugPrint('$stackTrace');
      rethrow;
    } on Object catch (error, stackTrace) {
      _debugStaffLog(
        'Stream error. collection=$collectionPath path=$collectionPath '
        'error=$error',
      );
      if (kDebugMode) debugPrint('$stackTrace');
      rethrow;
    }
  }

  Stream<List<AdminDocumentRow>> watchTeamMembersTable({int limit = 500}) {
    final controller = StreamController<List<AdminDocumentRow>>();
    final subscriptions = <StreamSubscription<List<AdminDocumentRow>>>[];
    var staffRows = const <AdminDocumentRow>[];
    var inviteRows = const <AdminDocumentRow>[];
    var hasStaffSnapshot = false;
    var hasInviteSnapshot = false;

    void publishMerged() {
      if (controller.isClosed) return;
      if (!hasStaffSnapshot && !hasInviteSnapshot) return;
      controller.add(
        _mergeTeamMembersRows(
          hasStaffSnapshot ? staffRows : const [],
          hasInviteSnapshot ? inviteRows : const [],
        ),
      );
    }

    controller.onListen = () {
      subscriptions.add(
        watchStaffCollection(limit: limit).listen((rows) {
          staffRows = rows;
          hasStaffSnapshot = true;
          publishMerged();
        }, onError: controller.addError),
      );
      subscriptions.add(
        watchStaffInvitesCollection(limit: limit).listen(
          (rows) {
            inviteRows = rows;
            hasInviteSnapshot = true;
            publishMerged();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (kDebugMode) {
              debugPrint(
                '[TeamMembersRepository] staff_invites stream error: $error',
              );
              debugPrint('$stackTrace');
            }
            hasInviteSnapshot = true;
            inviteRows = const [];
            publishMerged();
          },
        ),
      );
    };

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      subscriptions.clear();
    };

    return controller.stream;
  }

  List<AdminDocumentRow> _mergeTeamMembersRows(
    List<AdminDocumentRow> staff,
    List<AdminDocumentRow> invites,
  ) {
    final staffEmails = <String>{};
    for (final row in staff) {
      final email = _normalizedStaffEmail(row);
      if (email.isNotEmpty) staffEmails.add(email);
    }

    final mergedInvites = <AdminDocumentRow>[];
    for (final invite in invites) {
      final status = invite
          .readString(['status'], fallback: 'pending')
          .trim()
          .toLowerCase();
      if (status == 'removed') continue;

      final email = _normalizedStaffEmail(invite);
      if (email.isNotEmpty && staffEmails.contains(email)) continue;

      mergedInvites.add(
        AdminDocumentRow(
          id: invite.id,
          path: invite.path,
          data: {
            ...invite.data,
            'emailLower': email.isNotEmpty ? email : invite.data['emailLower'],
            'active': false,
            'isActive': false,
            if (invite.data['status'] == null ||
                invite.data['status'].toString().trim().isEmpty)
              'status': 'pending',
          },
        ),
      );
    }

    return [...staff, ...mergedInvites];
  }

  String _normalizedStaffEmail(AdminDocumentRow row) {
    final emailLower = row
        .readString(['emailLower'], fallback: '')
        .trim()
        .toLowerCase();
    if (emailLower.isNotEmpty && emailLower != '—') return emailLower;
    return row.readString(['email'], fallback: '').trim().toLowerCase();
  }

  Future<StaffInviteUpsertResult> upsertStaffInvite({
    required String email,
    required String role,
    required int roleLevel,
    required String invitedBy,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw ArgumentError('A valid email is required.');
    }

    if (await _hasActiveStaffMember(normalizedEmail)) {
      return StaffInviteUpsertResult.alreadyStaffMember;
    }

    final invites = firestore.collection('staff_invites');
    final existingInvite = await _findStaffInviteReference(
      invites,
      normalizedEmail,
    );

    final payload = {
      'email': normalizedEmail,
      'emailLower': normalizedEmail,
      'role': role,
      'roleLevel': roleLevel,
      'invitedBy': invitedBy,
      'invitedAt': FieldValue.serverTimestamp(),
      'status': 'invited',
      'active': false,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (existingInvite != null) {
      await existingInvite.set(payload, SetOptions(merge: true));
      return StaffInviteUpsertResult.updated;
    }

    await invites.add({...payload, 'createdAt': FieldValue.serverTimestamp()});

    // TODO(staff-onboarding): When invited user signs in, match
    // staff_invites.emailLower to auth email and create staff/{uid}
    // TODO(staff-onboarding): After staff/{uid} is created, mark invite as accepted
    // TODO(staff-onboarding): Store acceptedAt and acceptedByUid on the invite document

    return StaffInviteUpsertResult.created;
  }

  Future<bool> _hasActiveStaffMember(String normalizedEmail) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return false;

    final staff = firestore.collection('staff');
    for (final field in ['emailLower', 'email']) {
      final snapshot = await staff
          .where(field, isEqualTo: normalizedEmail)
          .limit(5)
          .get();
      for (final doc in snapshot.docs) {
        final status =
            doc.data()['status']?.toString().trim().toLowerCase() ?? '';
        if (status != 'removed') {
          return true;
        }
      }
    }
    return false;
  }

  Future<DocumentReference<Map<String, dynamic>>?> _findStaffInviteReference(
    CollectionReference<Map<String, dynamic>> invites,
    String normalizedEmail,
  ) async {
    for (final field in ['emailLower', 'email']) {
      final snapshot = await invites
          .where(field, isEqualTo: normalizedEmail)
          .limit(5)
          .get();
      for (final doc in snapshot.docs) {
        return doc.reference;
      }
    }
    return null;
  }

  void _debugStaffLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[TeamMembersRepository] $message');
  }

  Stream<int> watchCollectionCount(String collectionPath) {
    return watchCollection(
      collectionPath,
      limit: 500,
    ).map((rows) => rows.length);
  }

  Stream<int> watchVenueCount({required bool claimed}) {
    return watchCollection('venues', limit: 500).map((venues) {
      return venues.where((venue) {
        final ownerId = venue.readString(['ownerId'], fallback: '');
        final status = venue.readString([
          'claimStatus',
          'claimedStatus',
          'status',
        ], fallback: '').toLowerCase();
        final isClaimed =
            ownerId.isNotEmpty || status == 'claimed' || status == 'approved';
        return claimed ? isClaimed : !isClaimed;
      }).length;
    });
  }

  Stream<int> watchPendingVenueReviewCount() {
    return watchCollection('venues', limit: 500).map((venues) {
      return venues.where((venue) {
        final verified = venue.readBool(['isVerified', 'verified']);
        final ownerId = venue.readString(['ownerId'], fallback: '');
        return !verified || ownerId.isEmpty;
      }).length;
    });
  }

  Stream<int> watchTodaySignups() {
    final firestore = _resolveFirestore();
    if (firestore == null) return Stream.value(0);

    return firestore
        .collection('users')
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          debugPrint('[TEST users limit(1)] $error');
          return 0;
        });
  }

  Future<void> updateDocument({
    required String path,
    required Map<String, dynamic> updates,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    await firestore.doc(path).set({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // TODO(admin-audit): write audit_logs/{id} from a trusted backend path
    // once security rules and Cloud Functions define immutable audit writes.
  }

  Future<void> createDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    await firestore.collection(collectionPath).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDocument({required String path}) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    await firestore.doc(path).delete();
  }

  Future<void> suspendUser({
    required String uid,
    required String suspendedBy,
  }) async {
    await updateDocument(
      path: 'users/$uid',
      updates: {
        'status': 'suspended',
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedBy': suspendedBy,
      },
    );

    // TODO(admin-audit): audit user suspended
  }

  Future<void> unsuspendUser({
    required String uid,
    required String unsuspendedBy,
  }) async {
    await updateDocument(
      path: 'users/$uid',
      updates: {
        'status': 'active',
        'unsuspendedAt': FieldValue.serverTimestamp(),
        'unsuspendedBy': unsuspendedBy,
      },
    );

    // TODO(admin-audit): audit user unsuspended
  }

  /// Restores a disabled or suspended user account to active status.
  Future<void> restoreUserAccount({
    required String uid,
    required String restoredBy,
  }) async {
    await updateDocument(
      path: 'users/$uid',
      updates: {
        'status': 'active',
        'disabled': false,
        'isSuspended': false,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': restoredBy,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // TODO(admin-audit): audit user restored
  }

  /// Archives user data to [deleted_users] then soft-deletes the active doc.
  Future<void> archiveAndRemoveUser({
    required String uid,
    required String deletedBy,
    String? deleteReason,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final userRef = firestore.doc('users/$uid');
    final archiveRef = firestore.doc('deleted_users/$uid');
    final trimmedReason = deleteReason?.trim();

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw StateError('User not found.');
      }

      final data = Map<String, dynamic>.from(snapshot.data()!);
      if (data['isDeleted'] == true) {
        throw StateError('User is already deleted.');
      }

      transaction.set(archiveRef, {
        'originalUserId': uid,
        'originalUserData': data,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': deletedBy,
        if (trimmedReason != null && trimmedReason.isNotEmpty)
          'deleteReason': trimmedReason,
      });

      transaction.update(userRef, {
        'isDeleted': true,
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': deletedBy,
        if (trimmedReason != null && trimmedReason.isNotEmpty)
          'deleteReason': trimmedReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Map<String, dynamic>?> fetchAccountDeletionRequest(String uid) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return null;

    try {
      final snapshot = await firestore
          .collection('account_deletion_requests')
          .doc(uid)
          .get();
      if (!snapshot.exists) return null;
      return snapshot.data();
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[AdminUsersCrm] account_deletion_requests/$uid '
          'code=${error.code} message=${error.message}',
        );
      }
      return null;
    }
  }

  Future<AdminUserFavouritesResult> fetchUserFavouritesResult(
    String uid, {
    int limit = 20,
  }) async {
    if (_favouritesAccessDenied) {
      return _favouritesResultCache[uid] ??
          const AdminUserFavouritesResult(
            favourites: [],
            access: AdminUserFavouritesAccess.unavailable,
          );
    }

    final cached = _favouritesResultCache[uid];
    if (cached != null) return cached;

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return const AdminUserFavouritesResult(
        favourites: [],
        access: AdminUserFavouritesAccess.available,
      );
    }

    try {
      final snapshot = await firestore
          .collection('favourites')
          .where('userId', isEqualTo: uid)
          .limit(limit)
          .get();
      final result = AdminUserFavouritesResult(
        favourites: snapshot.docs
            .map(
              (doc) => AdminDocumentRow(
                id: doc.id,
                path: doc.reference.path,
                data: doc.data(),
              ),
            )
            .toList(growable: false),
        access: AdminUserFavouritesAccess.available,
      );
      _favouritesResultCache[uid] = result;
      return result;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _favouritesAccessDenied = true;
        final unavailable = const AdminUserFavouritesResult(
          favourites: [],
          access: AdminUserFavouritesAccess.unavailable,
        );
        _favouritesResultCache[uid] = unavailable;
        _logFavouritesUnavailableOnce(uid);
        return unavailable;
      }
      if (kDebugMode) {
        debugPrint(
          '[AdminUsersCrm] favourites uid=$uid '
          'code=${error.code} message=${error.message}',
        );
      }
      return const AdminUserFavouritesResult(
        favourites: [],
        access: AdminUserFavouritesAccess.available,
      );
    }
  }

  static final Map<String, AdminUserFavouritesResult> _favouritesResultCache =
      {};
  static final Set<String> _favouritesDeniedLogged = {};
  static bool _favouritesAccessDenied = false;

  static void _logFavouritesUnavailableOnce(String uid) {
    if (!kDebugMode || _favouritesDeniedLogged.contains(uid)) return;
    _favouritesDeniedLogged.add(uid);
    debugPrint(
      '[AdminUsersCrm] favourites unavailable for uid=$uid (permission denied)',
    );
  }

  Future<List<AdminDocumentRow>> fetchReportsForUser(
    String uid, {
    int limit = 250,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return const [];

    try {
      final snapshot = await firestore.collection('reports').limit(limit).get();
      final linked = snapshot.docs.where((doc) {
        final data = doc.data();
        for (final key in const [
          'userId',
          'reportedUserId',
          'targetUserId',
          'createdBy',
          'reporterId',
        ]) {
          if (data[key]?.toString() == uid) return true;
        }
        return false;
      });

      return linked
          .map(
            (doc) => AdminDocumentRow(
              id: doc.id,
              path: doc.reference.path,
              data: doc.data(),
            ),
          )
          .toList(growable: false);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[AdminUsersCrm] reports uid=$uid '
          'code=${error.code} message=${error.message}',
        );
      }
      return const [];
    }
  }

  Future<AdminUserVenueOwnerContext> fetchUserVenueOwnerContext(
    String uid, {
    Map<String, dynamic>? userData,
  }) async {
    if (_venueOwnerContextCache.containsKey(uid)) {
      return _venueOwnerContextCache[uid]!;
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return const AdminUserVenueOwnerContext(ownedVenuesCount: 0);
    }

    try {
      final venues = <AdminDocumentRow>[];
      final seenIds = <String>{};

      void addVenueDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
        if (!doc.exists || doc.data() == null) return;
        if (!seenIds.add(doc.id)) return;
        venues.add(
          AdminDocumentRow(
            id: doc.id,
            path: doc.reference.path,
            data: doc.data()!,
          ),
        );
      }

      void addVenueQueryDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        if (doc.data()['isDeleted'] == true) return;
        addVenueDoc(doc);
      }

      final ownedSnapshot = await firestore
          .collection('venues')
          .where('ownerId', isEqualTo: uid)
          .limit(10)
          .get();
      for (final doc in ownedSnapshot.docs) {
        addVenueQueryDoc(doc);
      }

      final venueIds = _parseVenueIds(userData?['venueIds']);
      for (final venueId in venueIds) {
        if (seenIds.contains(venueId)) continue;
        final doc = await firestore.collection('venues').doc(venueId).get();
        addVenueDoc(doc);
      }

      final primary = venues.isEmpty ? null : venues.first;
      int? drinksCount;
      int? dealsCount;
      int? eventsCount;
      if (primary != null) {
        drinksCount = await _countVenueLinkedCollection(
          collection: 'drinks',
          venueId: primary.id,
        );
        dealsCount = await _countVenueLinkedCollection(
          collection: 'deals',
          venueId: primary.id,
        );
        eventsCount = await _countVenueLinkedCollection(
          collection: 'events',
          venueId: primary.id,
        );
      }

      final result = AdminUserVenueOwnerContext(
        ownedVenuesCount: venues.length,
        primaryVenue: primary,
        drinksCount: drinksCount,
        dealsCount: dealsCount,
        eventsCount: eventsCount,
      );
      _venueOwnerContextCache[uid] = result;
      return result;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _logVenueOwnerUnavailableOnce(uid);
        final unavailable = const AdminUserVenueOwnerContext(
          ownedVenuesCount: 0,
          unavailable: true,
        );
        _venueOwnerContextCache[uid] = unavailable;
        return unavailable;
      }
      if (kDebugMode) {
        debugPrint(
          '[AdminUsersCrm] venue owner context uid=$uid '
          'code=${error.code} message=${error.message}',
        );
      }
      return const AdminUserVenueOwnerContext(ownedVenuesCount: 0);
    }
  }

  Future<AdminUserArtistContext> fetchUserArtistProfileContext(
    String uid,
  ) async {
    if (_artistContextCache.containsKey(uid)) {
      return _artistContextCache[uid]!;
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return const AdminUserArtistContext();
    }

    try {
      AdminDocumentRow? profile;

      final directDoc = await firestore
          .collection('artist_profiles')
          .doc(uid)
          .get();
      if (directDoc.exists) {
        profile = AdminDocumentRow(
          id: directDoc.id,
          path: directDoc.reference.path,
          data: directDoc.data() ?? const {},
        );
      } else {
        for (final field in const ['userId', 'uid', 'ownerId']) {
          final snapshot = await firestore
              .collection('artists')
              .where(field, isEqualTo: uid)
              .limit(1)
              .get();
          if (snapshot.docs.isEmpty) continue;
          final doc = snapshot.docs.first;
          profile = AdminDocumentRow(
            id: doc.id,
            path: doc.reference.path,
            data: doc.data(),
          );
          break;
        }
      }

      final result = AdminUserArtistContext(profile: profile);
      _artistContextCache[uid] = result;
      return result;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _logArtistContextUnavailableOnce(uid);
        final unavailable = const AdminUserArtistContext(unavailable: true);
        _artistContextCache[uid] = unavailable;
        return unavailable;
      }
      if (kDebugMode) {
        debugPrint(
          '[AdminUsersCrm] artist context uid=$uid '
          'code=${error.code} message=${error.message}',
        );
      }
      return const AdminUserArtistContext();
    }
  }

  static List<String> _parseVenueIds(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<int?> _countVenueLinkedCollection({
    required String collection,
    required String venueId,
    Map<String, Object?> extraEquals = const {},
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return null;

    try {
      Query<Map<String, dynamic>> query = firestore
          .collection(collection)
          .where('venueId', isEqualTo: venueId);
      for (final entry in extraEquals.entries) {
        query = query.where(entry.key, isEqualTo: entry.value);
      }
      query = query.where('isDeleted', isEqualTo: false);
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } on FirebaseException {
      try {
        final snapshot = await firestore
            .collection(collection)
            .where('venueId', isEqualTo: venueId)
            .limit(250)
            .get();
        return snapshot.docs.where((doc) {
          final data = doc.data();
          if (data['isDeleted'] == true) return false;
          for (final entry in extraEquals.entries) {
            if (data[entry.key] != entry.value) return false;
          }
          return true;
        }).length;
      } on FirebaseException {
        return null;
      }
    }
  }

  static final Map<String, AdminUserVenueOwnerContext> _venueOwnerContextCache =
      {};
  static final Map<String, AdminUserArtistContext> _artistContextCache = {};
  static final Set<String> _venueOwnerDeniedLogged = {};
  static final Set<String> _artistContextDeniedLogged = {};

  static void _logVenueOwnerUnavailableOnce(String uid) {
    if (!kDebugMode || _venueOwnerDeniedLogged.contains(uid)) return;
    _venueOwnerDeniedLogged.add(uid);
    debugPrint(
      '[AdminUsersCrm] venue owner context unavailable for uid=$uid '
      '(permission denied)',
    );
  }

  static void _logArtistContextUnavailableOnce(String uid) {
    if (!kDebugMode || _artistContextDeniedLogged.contains(uid)) return;
    _artistContextDeniedLogged.add(uid);
    debugPrint(
      '[AdminUsersCrm] artist context unavailable for uid=$uid '
      '(permission denied)',
    );
  }

  Future<AdminVenueContentSummary> fetchVenueContentSummary(
    String venueId,
  ) async {
    if (_venueContentCache.containsKey(venueId)) {
      return _venueContentCache[venueId]!;
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return const AdminVenueContentSummary();
    }

    try {
      final drinksCount = await _countVenueLinkedCollection(
        collection: 'drinks',
        venueId: venueId,
      );
      final dealsCount = await _countVenueLinkedCollection(
        collection: 'deals',
        venueId: venueId,
      );
      final eventsCount = await _countVenueLinkedCollection(
        collection: 'events',
        venueId: venueId,
      );

      final liveDeals = await _countVenueLinkedCollection(
        collection: 'deals',
        venueId: venueId,
        extraEquals: const {'isActive': true},
      );
      final upcomingEvents = await _countUpcomingEvents(venueId);

      final result = AdminVenueContentSummary(
        drinksCount: drinksCount,
        dealsCount: dealsCount,
        eventsCount: eventsCount,
        liveDealsCount: liveDeals,
        upcomingEventsCount: upcomingEvents,
      );
      _venueContentCache[venueId] = result;
      return result;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _logVenueContentUnavailableOnce(venueId);
        final unavailable = const AdminVenueContentSummary(unavailable: true);
        _venueContentCache[venueId] = unavailable;
        return unavailable;
      }
      if (kDebugMode) {
        debugPrint(
          '[AdminVenuesCrm] content venueId=$venueId '
          'code=${error.code} message=${error.message}',
        );
      }
      return const AdminVenueContentSummary();
    }
  }

  Future<AdminVenueOwnerContext> fetchVenueOwnerContext(
    String ownerId, {
    Map<String, dynamic>? venueData,
  }) async {
    if (ownerId.isEmpty || ownerId == '—') {
      return const AdminVenueOwnerContext();
    }
    if (_venueOwnerDetailsCache.containsKey(ownerId)) {
      return _venueOwnerDetailsCache[ownerId]!;
    }

    final firestore = _resolveFirestore();
    if (firestore == null) return const AdminVenueOwnerContext();

    try {
      final userDoc = await firestore.collection('users').doc(ownerId).get();
      if (!userDoc.exists || userDoc.data() == null) {
        return AdminVenueOwnerContext(ownerUid: ownerId);
      }

      final data = userDoc.data()!;
      final row = AdminDocumentRow(
        id: userDoc.id,
        path: userDoc.reference.path,
        data: data,
      );

      int? ownedCount;
      try {
        final owned = await firestore
            .collection('venues')
            .where('ownerId', isEqualTo: ownerId)
            .limit(25)
            .get();
        ownedCount = owned.docs
            .where((doc) => doc.data()['isDeleted'] != true)
            .length;
      } on FirebaseException {
        ownedCount = null;
      }

      final managerIds = data['managerIds'];
      final teamCount = managerIds is List ? managerIds.length : null;

      final stripeSubscription = await _readOwnerStripeSubscription(
        firestore,
        ownerId,
      );

      final rawTier = _resolveOwnerSubscriptionTierRaw(
        userData: data,
        venueData: venueData,
        stripePlan: stripeSubscription?.planId,
      );
      final rawStatus = _resolveOwnerSubscriptionStatusRaw(
        userData: data,
        stripeStatus: stripeSubscription?.status,
      );

      final result = AdminVenueOwnerContext(
        ownerName: row.readString(['displayName', 'name', 'fullName']),
        ownerEmail: row.readString(['email']),
        ownerStatus: row.readString(['status'], fallback: 'active'),
        ownerUid: ownerId,
        subscriptionTier: formatAdminVenueSubscriptionTier(rawTier),
        subscriptionStatus: formatAdminVenueSubscriptionStatus(rawStatus),
        venueLimit:
            _parseOptionalInt(data['venueLimit'] ?? data['maxVenues']) ??
            _defaultVenueLimitForTier(rawTier),
        ownedVenuesCount: ownedCount,
        teamMembersCount: teamCount,
      );
      _venueOwnerDetailsCache[ownerId] = result;
      return result;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _logVenueOwnerDetailsUnavailableOnce(ownerId);
        final unavailable = AdminVenueOwnerContext(
          ownerUid: ownerId,
          unavailable: true,
        );
        _venueOwnerDetailsCache[ownerId] = unavailable;
        return unavailable;
      }
      return AdminVenueOwnerContext(ownerUid: ownerId);
    }
  }

  Future<({String? planId, String? status})?> _readOwnerStripeSubscription(
    FirebaseFirestore firestore,
    String ownerId,
  ) async {
    try {
      final subscriptions = await firestore
          .collection('customers')
          .doc(ownerId)
          .collection('subscriptions')
          .where('status', whereIn: const ['trialing', 'active', 'past_due'])
          .limit(5)
          .get();

      for (final doc in subscriptions.docs) {
        final subscriptionData = doc.data();
        final metadata = subscriptionData['metadata'];
        if (metadata is Map) {
          final appPlan = metadata['app_plan']?.toString().trim();
          if (appPlan != null && appPlan.isNotEmpty) {
            return (
              planId: appPlan,
              status: subscriptionData['status']?.toString(),
            );
          }
        }

        final items = subscriptionData['items'];
        if (items is List) {
          for (final item in items) {
            if (item is! Map) continue;
            final price = item['price'];
            if (price is! Map) continue;
            final product = price['product'];
            if (product is Map && product['metadata'] is Map) {
              final appPlan = (product['metadata'] as Map)['app_plan']
                  ?.toString()
                  .trim();
              if (appPlan != null && appPlan.isNotEmpty) {
                return (
                  planId: appPlan,
                  status: subscriptionData['status']?.toString(),
                );
              }
            }
          }
        }
      }

      final customerDoc = await firestore
          .collection('customers')
          .doc(ownerId)
          .get();
      if (customerDoc.exists && customerDoc.data() != null) {
        final customerData = customerDoc.data()!;
        final plan =
            customerData['subscriptionPlan'] ??
            customerData['subscriptionPlanId'] ??
            customerData['plan'];
        final status =
            customerData['subscriptionStatus'] ?? customerData['status'];
        if (plan != null && plan.toString().trim().isNotEmpty) {
          return (planId: plan.toString(), status: status?.toString());
        }
      }
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        _logVenueSubscriptionLookupFailureOnce(ownerId, error);
      }
    }

    return null;
  }

  static String? _resolveOwnerSubscriptionTierRaw({
    required Map<String, dynamic> userData,
    Map<String, dynamic>? venueData,
    String? stripePlan,
  }) {
    if (userData['ownerSubscriptionActive'] == true) {
      return userData['ownerSubscriptionPlan']?.toString() ?? 'venue_pro';
    }

    final candidates = <Object?>[
      stripePlan,
      userData['ownerSubscriptionPlan'],
      userData['subscriptionPlanId'],
      userData['subscriptionPlan'],
      userData['plan'],
      userData['planId'],
      venueData?['subscriptionPlanId'],
      venueData?['subscriptionPlan'],
      venueData?['plan'],
      venueData?['planId'],
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty && text != '—') {
        return text;
      }
    }

    return null;
  }

  static String? _resolveOwnerSubscriptionStatusRaw({
    required Map<String, dynamic> userData,
    String? stripeStatus,
  }) {
    if (userData['ownerSubscriptionActive'] == true) {
      return 'active';
    }

    final stripe = stripeStatus?.trim();
    if (stripe != null && stripe.isNotEmpty) {
      return stripe;
    }

    for (final key in [
      'subscriptionStatus',
      'subscriptionState',
      'billingStatus',
    ]) {
      final value = userData[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != '—') {
        return value;
      }
    }

    return null;
  }

  static int? _defaultVenueLimitForTier(String? rawTier) {
    final normalized = rawTier?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
    if (normalized.isEmpty) return null;
    if (normalized.contains('corporate')) return null;
    return 1;
  }

  Future<AdminVenueClaimInfo> fetchVenueClaimInfo(
    String venueId, {
    Map<String, dynamic>? venueData,
  }) async {
    if (_venueClaimCache.containsKey(venueId)) {
      return _venueClaimCache[venueId]!;
    }

    final firestore = _resolveFirestore();
    final base = AdminVenueClaimInfo(
      claimStatus:
          venueData?['claimStatus']?.toString() ??
          venueData?['claimedStatus']?.toString(),
      claimedByUserId: venueData?['ownerId']?.toString(),
      claimedVenueId: venueId,
    );

    if (firestore == null) {
      return base;
    }

    try {
      final doc = await firestore
          .collection('venue_claim_directory')
          .doc(venueId)
          .get();
      if (!doc.exists || doc.data() == null) {
        _venueClaimCache[venueId] = base;
        return base;
      }

      final data = doc.data()!;
      final row = AdminDocumentRow(
        id: doc.id,
        path: doc.reference.path,
        data: data,
      );

      final result = AdminVenueClaimInfo(
        claimStatus: row.readString([
          'claimStatus',
          'status',
          'claimedStatus',
        ], fallback: base.claimStatus ?? '—'),
        claimedByUserId: row.readString([
          'claimedBy',
          'ownerId',
          'userId',
        ], fallback: base.claimedByUserId ?? '—'),
        claimedVenueId: row.readString([
          'venueId',
          'claimedVenueId',
        ], fallback: venueId),
        directorySource: 'venue_claim_directory',
        claimCreatedAt: _readDateFromMap(data, const [
          'createdAt',
          'created_at',
        ]),
        claimUpdatedAt: _readDateFromMap(data, const [
          'updatedAt',
          'updated_at',
        ]),
      );
      _venueClaimCache[venueId] = result;
      return result;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        _logVenueClaimUnavailableOnce(venueId);
        final unavailable = AdminVenueClaimInfo(unavailable: true);
        _venueClaimCache[venueId] = unavailable;
        return unavailable;
      }
      _venueClaimCache[venueId] = base;
      return base;
    }
  }

  Future<List<AdminDocumentRow>> fetchReportsForVenue(
    String venueId, {
    int limit = 250,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return const [];

    try {
      final snapshot = await firestore.collection('reports').limit(limit).get();
      final linked = snapshot.docs.where((doc) {
        final data = doc.data();
        for (final key in const [
          'venueId',
          'targetVenueId',
          'reportedVenueId',
        ]) {
          if (data[key]?.toString() == venueId) return true;
        }
        return false;
      });

      return linked
          .map(
            (doc) => AdminDocumentRow(
              id: doc.id,
              path: doc.reference.path,
              data: doc.data(),
            ),
          )
          .toList(growable: false);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[AdminVenuesCrm] reports venueId=$venueId '
          'code=${error.code} message=${error.message}',
        );
      }
      return const [];
    }
  }

  /// Hides a venue from public listings while keeping it in the admin CRM.
  Future<void> hideVenueFromPublic({
    required String venueId,
    required String hiddenBy,
  }) async {
    await updateDocument(
      path: 'venues/$venueId',
      updates: {
        'isVisible': false,
        'publicVisible': false,
        'searchablePublic': false,
        'isHidden': true,
        'status': 'hidden',
        'hiddenAt': FieldValue.serverTimestamp(),
        'hiddenBy': hiddenBy,
      },
    );
  }

  /// Restores public visibility for a hidden venue.
  Future<void> publishVenueToPublic({
    required String venueId,
    required String publishedBy,
  }) async {
    await updateDocument(
      path: 'venues/$venueId',
      updates: {
        'isVisible': true,
        'publicVisible': true,
        'searchablePublic': true,
        'isHidden': false,
        'status': 'active',
        'publishedAt': FieldValue.serverTimestamp(),
        'publishedBy': publishedBy,
      },
    );
  }

  /// Archives venue data to [deleted_venues] then marks the active doc deleted.
  Future<void> archiveAndRemoveVenue({
    required String venueId,
    required String deletedBy,
    String? deleteReason,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final venueRef = firestore.doc('venues/$venueId');
    final archiveRef = firestore.doc('deleted_venues/$venueId');
    final trimmedReason = deleteReason?.trim();

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(venueRef);
      if (!snapshot.exists) {
        throw StateError('Venue not found.');
      }

      final data = Map<String, dynamic>.from(snapshot.data()!);
      if (data['isDeleted'] == true) {
        throw StateError('Venue is already deleted.');
      }

      transaction.set(archiveRef, {
        'originalVenueId': venueId,
        'originalVenueData': data,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': deletedBy,
        if (trimmedReason != null && trimmedReason.isNotEmpty)
          'deleteReason': trimmedReason,
      });

      transaction.update(venueRef, {
        'isDeleted': true,
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': deletedBy,
        if (trimmedReason != null && trimmedReason.isNotEmpty)
          'deleteReason': trimmedReason,
        'isVisible': false,
        'publicVisible': false,
        'searchablePublic': false,
        'isHidden': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Soft-suspends a venue listing. Does not delete venue data.
  ///
  /// TODO(audit): Record suspend action in admin audit log when backend exists.
  Future<void> suspendVenue({
    required String venueId,
    required String suspendedBy,
  }) async {
    await updateDocument(
      path: 'venues/$venueId',
      updates: {
        'status': 'suspended',
        'publicVisible': false,
        'searchablePublic': false,
        'isVisible': false,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedBy': suspendedBy,
      },
    );
  }

  /// Restores a soft-suspended venue listing.
  ///
  /// TODO(audit): Record unsuspend action in admin audit log when backend exists.
  Future<void> unsuspendVenue({
    required String venueId,
    required String unsuspendedBy,
  }) async {
    await updateDocument(
      path: 'venues/$venueId',
      updates: {
        'status': 'active',
        'publicVisible': true,
        'searchablePublic': true,
        'isVisible': true,
        'unsuspendedAt': FieldValue.serverTimestamp(),
        'unsuspendedBy': unsuspendedBy,
      },
    );
  }

  /// Sets venue verification state.
  ///
  /// TODO(audit): Record verify/unverify action in admin audit log when backend exists.
  Future<void> setVenueVerified({
    required String venueId,
    required bool verified,
    required String updatedBy,
  }) async {
    await updateDocument(
      path: 'venues/$venueId',
      updates: {
        'isVerified': verified,
        'verified': verified,
        if (verified) ...{
          'verifiedAt': FieldValue.serverTimestamp(),
          'verifiedBy': updatedBy,
        } else ...{
          'unverifiedAt': FieldValue.serverTimestamp(),
          'unverifiedBy': updatedBy,
        },
      },
    );
  }

  static int? _parseOptionalInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _readDateFromMap(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) {
        final local = value.toDate().toLocal();
        return '${local.day.toString().padLeft(2, '0')}/'
            '${local.month.toString().padLeft(2, '0')}/'
            '${local.year}';
      }
    }
    return null;
  }

  Future<int?> _countUpcomingEvents(String venueId) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return null;

    try {
      final snapshot = await firestore
          .collection('events')
          .where('venueId', isEqualTo: venueId)
          .where('isDeleted', isEqualTo: false)
          .limit(100)
          .get();
      final now = DateTime.now();
      return snapshot.docs.where((doc) {
        final start = doc.data()['startAt'] ?? doc.data()['startDate'];
        if (start is Timestamp) return start.toDate().isAfter(now);
        return true;
      }).length;
    } on FirebaseException {
      return null;
    }
  }

  static final Map<String, AdminVenueContentSummary> _venueContentCache = {};
  static final Map<String, AdminVenueOwnerContext> _venueOwnerDetailsCache = {};
  static final Map<String, AdminVenueClaimInfo> _venueClaimCache = {};
  static final Set<String> _venueContentDeniedLogged = {};
  static final Set<String> _venueOwnerDetailsDeniedLogged = {};
  static final Set<String> _venueClaimDeniedLogged = {};
  static final Set<String> _venueSubscriptionLookupFailureLogged = {};

  static void _logVenueContentUnavailableOnce(String venueId) {
    if (!kDebugMode || _venueContentDeniedLogged.contains(venueId)) return;
    _venueContentDeniedLogged.add(venueId);
    debugPrint(
      '[AdminVenuesCrm] content unavailable for venueId=$venueId '
      '(permission denied)',
    );
  }

  static void _logVenueOwnerDetailsUnavailableOnce(String ownerId) {
    if (!kDebugMode || _venueOwnerDetailsDeniedLogged.contains(ownerId)) return;
    _venueOwnerDetailsDeniedLogged.add(ownerId);
    debugPrint(
      '[AdminVenuesCrm] owner lookup unavailable for uid=$ownerId '
      '(permission denied)',
    );
  }

  static void _logVenueSubscriptionLookupFailureOnce(
    String ownerId,
    FirebaseException error,
  ) {
    if (!kDebugMode ||
        _venueSubscriptionLookupFailureLogged.contains(ownerId)) {
      return;
    }
    _venueSubscriptionLookupFailureLogged.add(ownerId);
    debugPrint(
      '[AdminVenuesCrm] subscription lookup failed for uid=$ownerId '
      'code=${error.code} message=${error.message}',
    );
  }

  static void _logVenueClaimUnavailableOnce(String venueId) {
    if (!kDebugMode || _venueClaimDeniedLogged.contains(venueId)) return;
    _venueClaimDeniedLogged.add(venueId);
    debugPrint(
      '[AdminVenuesCrm] claim directory unavailable for venueId=$venueId '
      '(permission denied)',
    );
  }
}
