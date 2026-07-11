import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/venue/application/venue_profile_update.dart';
import 'package:vex_engines/venue/data/venue_profile_write_repository.dart';

import '../../core/firebase/vexda_firebase.dart';
import 'web_vexcore.dart';

/// Firebase adapter for prepared venue profile updates.
final class FirebaseVenueProfileWriteRepository
    implements VenueProfileWriteRepository {
  FirebaseVenueProfileWriteRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  @override
  Future<DataResult<void>> applyVenueProfileUpdate({
    required String venueId,
    required VenueProfileUpdate update,
  }) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataFailure(
        VexException('Venue ID is required.', code: 'venue-id-required'),
      );
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return const DataFailure(
        VexException(
          'Firestore is not available.',
          code: 'firestore-unavailable',
        ),
      );
    }

    final payload = Map<String, dynamic>.from(update.fields);
    for (final field in update.serverTimestampFields) {
      payload[field] = FieldValue.serverTimestamp();
    }

    try {
      await firestore
          .collection('venues')
          .doc(trimmedId)
          .set(payload, SetOptions(merge: true));
      unawaited(
        WebVexCore.eventBus.publish(
          VenueProfileUpdatedEvent(
            venueId: trimmedId,
            updatedByUid: update.fields['ownerId']?.toString() ?? '',
          ),
        ),
      );
      return const DataSuccess(null);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueProfileWriteRepository] update failed '
          '(${error.code}): ${error.message}',
        );
      }
      return DataFailure(
        VexException(
          error.message ?? 'Failed to update venue profile.',
          code: error.code,
          cause: error,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueProfileWriteRepository] update failed: $error',
        );
        debugPrint('$stackTrace');
      }
      return DataFailure(
        VexException(
          'Failed to update venue profile.',
          code: 'venue-profile-update-failed',
          cause: error,
        ),
      );
    }
  }

  @visibleForTesting
  static Map<String, dynamic> buildFirestorePayload(VenueProfileUpdate update) {
    final payload = Map<String, dynamic>.from(update.fields);
    for (final field in update.serverTimestampFields) {
      payload[field] = FieldValue.serverTimestamp();
    }
    return payload;
  }
}
