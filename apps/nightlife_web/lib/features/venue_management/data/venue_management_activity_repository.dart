import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/venue_management_activity.dart';
import '../models/venue_management_activity_types.dart';

/// Persists append-only venue management activity records.
abstract class VenueManagementActivityRepository {
  Future<String> append(VenueManagementActivity activity);

  Future<List<VenueManagementActivity>> fetchRecentForVenue({
    required String venueId,
    int limit = 10,
  });

  Future<List<VenueManagementActivity>> fetchRecentForSourceArea({
    required String venueId,
    required String sourceArea,
    int limit = 10,
  });

  Future<List<VenueManagementActivity>> fetchRecentForEntity({
    required String venueId,
    required String entityType,
    required String entityId,
    int limit = 10,
  });
}

class FirebaseVenueManagementActivityRepository
    implements VenueManagementActivityRepository {
  FirebaseVenueManagementActivityRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  @override
  Future<String> append(VenueManagementActivity activity) async {
    if (!activity.isValidForWrite) {
      throw ArgumentError('Invalid venue management activity record.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final docRef = firestore
        .collection(VenueManagementActivityStorage.collection)
        .doc();

    try {
      await docRef.set(activity.toFirestore());
      return docRef.id;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueManagementActivityRepository] append failed '
          '(${error.code})',
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<VenueManagementActivity>> fetchRecentForVenue({
    required String venueId,
    int limit = 10,
  }) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return const [];

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    try {
      final snapshot = await firestore
          .collection(VenueManagementActivityStorage.collection)
          .where('venueId', isEqualTo: trimmedId)
          .orderBy('occurredAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => VenueManagementActivity.fromFirestore(doc.id, doc.data()))
          .toList(growable: false);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueManagementActivityRepository] fetchRecentForVenue '
          'failed (${error.code})',
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<VenueManagementActivity>> fetchRecentForSourceArea({
    required String venueId,
    required String sourceArea,
    int limit = 10,
  }) async {
    final trimmedVenueId = venueId.trim();
    final trimmedSourceArea = sourceArea.trim();
    if (trimmedVenueId.isEmpty || trimmedSourceArea.isEmpty) return const [];

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    try {
      final snapshot = await firestore
          .collection(VenueManagementActivityStorage.collection)
          .where('venueId', isEqualTo: trimmedVenueId)
          .where('sourceArea', isEqualTo: trimmedSourceArea)
          .orderBy('occurredAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => VenueManagementActivity.fromFirestore(doc.id, doc.data()))
          .toList(growable: false);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueManagementActivityRepository] fetchRecentForSourceArea '
          'failed (${error.code})',
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<VenueManagementActivity>> fetchRecentForEntity({
    required String venueId,
    required String entityType,
    required String entityId,
    int limit = 10,
  }) async {
    final trimmedVenueId = venueId.trim();
    final trimmedEntityType = entityType.trim();
    final trimmedEntityId = entityId.trim();
    if (trimmedVenueId.isEmpty ||
        trimmedEntityType.isEmpty ||
        trimmedEntityId.isEmpty) {
      return const [];
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    try {
      final snapshot = await firestore
          .collection(VenueManagementActivityStorage.collection)
          .where('venueId', isEqualTo: trimmedVenueId)
          .where('entityType', isEqualTo: trimmedEntityType)
          .where('entityId', isEqualTo: trimmedEntityId)
          .orderBy('occurredAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => VenueManagementActivity.fromFirestore(doc.id, doc.data()))
          .toList(growable: false);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueManagementActivityRepository] fetchRecentForEntity '
          'failed (${error.code})',
        );
      }
      rethrow;
    }
  }
}

/// In-memory repository for tests.
class InMemoryVenueManagementActivityRepository
    implements VenueManagementActivityRepository {
  InMemoryVenueManagementActivityRepository();

  final List<VenueManagementActivity> records = [];
  int _nextId = 0;

  @override
  Future<String> append(VenueManagementActivity activity) async {
    if (!activity.isValidForWrite) {
      throw ArgumentError('Invalid venue management activity record.');
    }

    final id = 'activity-${_nextId++}';
    records.add(
      activity.copyWith(
        activityId: id,
        occurredAt: activity.occurredAt ?? DateTime.now(),
      ),
    );
    return id;
  }

  @override
  Future<List<VenueManagementActivity>> fetchRecentForVenue({
    required String venueId,
    int limit = 10,
  }) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return const [];

    final filtered = records
        .where((record) => record.venueId == trimmedId)
        .toList()
      ..sort((a, b) {
        final aTime = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    return filtered.take(limit).toList(growable: false);
  }

  List<VenueManagementActivity> _sortedMatches(
    bool Function(VenueManagementActivity record) matches,
  ) {
    return records.where(matches).toList()
      ..sort((a, b) {
        final aTime = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
  }

  @override
  Future<List<VenueManagementActivity>> fetchRecentForSourceArea({
    required String venueId,
    required String sourceArea,
    int limit = 10,
  }) async {
    final trimmedVenueId = venueId.trim();
    final trimmedSourceArea = sourceArea.trim();
    if (trimmedVenueId.isEmpty || trimmedSourceArea.isEmpty) return const [];

    return _sortedMatches(
      (record) =>
          record.venueId == trimmedVenueId &&
          record.sourceArea == trimmedSourceArea,
    ).take(limit).toList(growable: false);
  }

  @override
  Future<List<VenueManagementActivity>> fetchRecentForEntity({
    required String venueId,
    required String entityType,
    required String entityId,
    int limit = 10,
  }) async {
    final trimmedVenueId = venueId.trim();
    final trimmedEntityType = entityType.trim();
    final trimmedEntityId = entityId.trim();
    if (trimmedVenueId.isEmpty ||
        trimmedEntityType.isEmpty ||
        trimmedEntityId.isEmpty) {
      return const [];
    }

    return _sortedMatches(
      (record) =>
          record.venueId == trimmedVenueId &&
          record.entityType == trimmedEntityType &&
          record.entityId == trimmedEntityId,
    ).take(limit).toList(growable: false);
  }
}
