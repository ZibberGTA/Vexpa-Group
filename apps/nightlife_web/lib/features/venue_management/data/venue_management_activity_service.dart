import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/venue_management_activity.dart';
import 'venue_management_activity_repository.dart';

/// Records and reads venue-scoped management activity.
abstract class VenueManagementActivityService {
  Future<void> recordActivity(VenueManagementActivity activity);

  Future<List<VenueManagementActivity>> loadRecentActivity({
    required String venueId,
    int limit = 10,
  });

  Future<List<VenueManagementActivity>> loadRecentActivityForSourceArea({
    required String venueId,
    required String sourceArea,
    int limit = 10,
  });

  Future<List<VenueManagementActivity>> loadRecentActivityForEntity({
    required String venueId,
    required String entityType,
    required String entityId,
    int limit = 10,
  });
}

class DefaultVenueManagementActivityService
    implements VenueManagementActivityService {
  DefaultVenueManagementActivityService({
    VenueManagementActivityRepository? repository,
  }) : _repository =
           repository ?? FirebaseVenueManagementActivityRepository();

  final VenueManagementActivityRepository _repository;

  @override
  Future<void> recordActivity(VenueManagementActivity activity) async {
    if (!activity.isValidForWrite) {
      if (kDebugMode) {
        debugPrint(
          '[VenueManagementActivityService] skipped invalid activity record',
        );
      }
      return;
    }

    try {
      await _repository.append(activity);
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueManagementActivityService] activity write failed '
          '(${error.code})',
        );
        debugPrint('$stackTrace');
      }
      // Activity must never block or fail the primary CRUD operation.
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueManagementActivityService] activity write failed: $error',
        );
        debugPrint('$stackTrace');
      }
      // Activity must never block or fail the primary CRUD operation.
    }
  }

  @override
  Future<List<VenueManagementActivity>> loadRecentActivity({
    required String venueId,
    int limit = 10,
  }) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return const [];

    try {
      return await _repository.fetchRecentForVenue(
        venueId: trimmedId,
        limit: limit,
      );
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueManagementActivityService] activity read failed '
          '(${error.code})',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueManagementActivityService] activity read failed: $error',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<List<VenueManagementActivity>> loadRecentActivityForSourceArea({
    required String venueId,
    required String sourceArea,
    int limit = 10,
  }) async {
    final trimmedVenueId = venueId.trim();
    final trimmedSourceArea = sourceArea.trim();
    if (trimmedVenueId.isEmpty || trimmedSourceArea.isEmpty) return const [];

    try {
      return await _repository.fetchRecentForSourceArea(
        venueId: trimmedVenueId,
        sourceArea: trimmedSourceArea,
        limit: limit,
      );
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueManagementActivityService] source activity read failed '
          '(${error.code})',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueManagementActivityService] source activity read failed: $error',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<List<VenueManagementActivity>> loadRecentActivityForEntity({
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

    try {
      return await _repository.fetchRecentForEntity(
        venueId: trimmedVenueId,
        entityType: trimmedEntityType,
        entityId: trimmedEntityId,
        limit: limit,
      );
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueManagementActivityService] entity activity read failed '
          '(${error.code})',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[VenueManagementActivityService] entity activity read failed: $error',
        );
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }
}

/// No-op service for tests that must not persist activity.
class NoOpVenueManagementActivityService
    implements VenueManagementActivityService {
  const NoOpVenueManagementActivityService();

  @override
  Future<void> recordActivity(VenueManagementActivity activity) async {}

  @override
  Future<List<VenueManagementActivity>> loadRecentActivity({
    required String venueId,
    int limit = 10,
  }) async =>
      const [];

  @override
  Future<List<VenueManagementActivity>> loadRecentActivityForSourceArea({
    required String venueId,
    required String sourceArea,
    int limit = 10,
  }) async =>
      const [];

  @override
  Future<List<VenueManagementActivity>> loadRecentActivityForEntity({
    required String venueId,
    required String entityType,
    required String entityId,
    int limit = 10,
  }) async =>
      const [];
}
