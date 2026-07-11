import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import 'mobile_vexcore.dart';

/// Firebase adapter for owner venue create and update writes.
class FirebaseVenueWriteRepository implements VenueWriteRepository {
  FirebaseVenueWriteRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? (_firestore ??= FirebaseFirestore.instance);

  @override
  Future<DataResult<String>> createVenue(VenueWritePayload payload) async {
    try {
      final doc = await _db.collection('venues').add(_buildFirestorePayload(payload));
      return DataSuccess(doc.id);
    } on FirebaseException catch (error) {
      return DataFailure(
        VexException(
          error.message ?? 'Failed to create venue.',
          code: error.code,
          cause: error,
        ),
      );
    } on Object catch (error, stackTrace) {
      _logFailure('createVenue', error, stackTrace);
      return DataFailure(
        VexException(
          'Failed to create venue.',
          code: 'venue-create-failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<DataResult<void>> updateVenue({
    required String venueId,
    required VenueWritePayload payload,
  }) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataFailure(
        VexException('Venue ID is required.', code: 'venue-id-required'),
      );
    }

    try {
      await _db
          .collection('venues')
          .doc(trimmedId)
          .update(_buildFirestorePayload(payload));
      unawaited(
        MobileVexCore.eventBus.publish(
          VenueProfileUpdatedEvent(
            venueId: trimmedId,
            updatedByUid: payload.fields['ownerId']?.toString() ?? '',
          ),
        ),
      );
      return const DataSuccess(null);
    } on FirebaseException catch (error) {
      return DataFailure(
        VexException(
          error.message ?? 'Failed to update venue.',
          code: error.code,
          cause: error,
        ),
      );
    } on Object catch (error, stackTrace) {
      _logFailure('updateVenue', error, stackTrace);
      return DataFailure(
        VexException(
          'Failed to update venue.',
          code: 'venue-update-failed',
          cause: error,
        ),
      );
    }
  }

  @visibleForTesting
  Map<String, dynamic> buildFirestorePayload(VenueWritePayload payload) {
    return _buildFirestorePayload(payload);
  }

  Map<String, dynamic> _buildFirestorePayload(VenueWritePayload payload) {
    final firestorePayload = Map<String, dynamic>.from(payload.fields);

    for (final field in payload.serverTimestampFields) {
      firestorePayload[field] = FieldValue.serverTimestamp();
    }

    final coordinates = payload.coordinates;
    if (coordinates != null) {
      firestorePayload['location'] = GeoPoint(
        coordinates.latitude,
        coordinates.longitude,
      );
    } else {
      firestorePayload['location'] = null;
    }

    return firestorePayload;
  }

  void _logFailure(String label, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[FirebaseVenueWriteRepository] $label failed: $error');
      debugPrint('$stackTrace');
    }
  }
}
