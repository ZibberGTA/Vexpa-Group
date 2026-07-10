import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../core/firebase/vexda_firebase.dart';
import '../../features/venue/data/models/event_model.dart';
import 'vex_venue_event_mapper.dart';

/// Firebase adapter for public venue event reads.
final class FirebaseVenueEventRepository implements VenueEventRepository {
  FirebaseVenueEventRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  @override
  Future<DataResult<List<VenueEvent>>> loadPublicEvents(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataSuccess([]);
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return const DataSuccess([]);
    }

    try {
      final snapshot = await firestore
          .collection('events')
          .where('venueId', isEqualTo: trimmedId)
          .where('isDeleted', isEqualTo: false)
          .get();

      return DataSuccess(mapEventDocuments(snapshot.docs));
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueEventRepository] loadPublicEvents failed '
          '(${error.code}): ${error.message}',
        );
      }
      return DataFailure(
        VexException(
          error.message ?? 'Failed to load venue events.',
          code: error.code,
          cause: error,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueEventRepository] loadPublicEvents failed: $error',
        );
        debugPrint('$stackTrace');
      }
      return DataFailure(
        VexException(
          'Failed to load venue events.',
          code: 'venue-event-load-failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<DataResult<List<VenueEvent>>> watchPublicEvents(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const DataSuccess([]));
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return Stream.value(const DataSuccess([]));
    }

    return firestore
        .collection('events')
        .where('venueId', isEqualTo: trimmedId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map<DataResult<List<VenueEvent>>>(
          (snapshot) => DataSuccess(mapEventDocuments(snapshot.docs)),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, EventSink sink) {
              if (kDebugMode) {
                debugPrint(
                  '[FirebaseVenueEventRepository] watchPublicEvents failed: '
                  '$error',
                );
                debugPrint('$stackTrace');
              }
              sink.add(
                DataFailure(
                  VexException(
                    'Failed to watch venue events.',
                    code: error is FirebaseException
                        ? error.code
                        : 'venue-event-watch-failed',
                    cause: error,
                  ),
                ),
              );
            },
          ),
        );
  }

  @visibleForTesting
  static VenueEvent? mapEventEntry(String id, Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }

    try {
      return vexVenueEventFromEventModel(EventModel.fromMap(id, data));
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueEventRepository] Malformed event document $id: $error',
        );
      }
      return null;
    }
  }

  @visibleForTesting
  static List<VenueEvent> mapEventDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return mapEventData(docs.map((doc) => MapEntry(doc.id, doc.data())));
  }

  @visibleForTesting
  static List<VenueEvent> mapEventData(
    Iterable<MapEntry<String, Map<String, dynamic>>> docs,
  ) {
    final events = <VenueEvent>[];
    for (final entry in docs) {
      final event = mapEventEntry(entry.key, entry.value);
      if (event != null) {
        events.add(event);
      }
    }
    return events;
  }
}
