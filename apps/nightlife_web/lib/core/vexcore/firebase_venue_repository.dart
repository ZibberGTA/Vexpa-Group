import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../core/firebase/vexda_firebase.dart';
import '../../features/venues/models/venue_model.dart';
import 'vex_venue_mapper.dart';

/// Firebase adapter for public venue discovery reads.
final class FirebaseVenueRepository implements VenueRepository {
  FirebaseVenueRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  @override
  Future<DataResult<List<Venue>>> loadPublicVenues() async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      return DataFailure(
        const VexException(
          'Firebase is not initialized.',
          code: 'firebase-unavailable',
        ),
      );
    }

    try {
      final snapshot = await firestore
          .collection('venues')
          .where('isDeleted', isEqualTo: false)
          .where('searchablePublic', isNotEqualTo: false)
          .get();

      final venues = mapVenueDocuments(snapshot.docs);
      return DataSuccess(venues);
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[FirebaseVenueRepository] loadPublicVenues failed: $error');
        debugPrint('$stackTrace');
      }
      return DataFailure(
        VexException(
          'Failed to load public venues.',
          code: 'venue-load-failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<DataResult<VenueSearchMatch>> searchPublicVenuesByTerms({
    required List<String> terms,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      return const DataSuccess(VenueSearchMatch(venueIds: {}));
    }

    if (terms.isEmpty) {
      return const DataSuccess(VenueSearchMatch(venueIds: {}));
    }

    try {
      final snapshot = await firestore
          .collection('venues')
          .where('isDeleted', isEqualTo: false)
          .where('searchablePublic', isNotEqualTo: false)
          .where('searchTerms', arrayContainsAny: terms)
          .get();

      return DataSuccess(
        VenueSearchMatch(venueIds: snapshot.docs.map((doc) => doc.id).toSet()),
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueRepository] searchPublicVenuesByTerms failed: $error',
        );
        debugPrint('$stackTrace');
      }
      return const DataSuccess(VenueSearchMatch(venueIds: {}));
    }
  }

  @override
  Future<DataResult<Venue?>> findById(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataSuccess(null);
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return DataFailure(
        const VexException(
          'Firebase is not initialized.',
          code: 'firebase-unavailable',
        ),
      );
    }

    try {
      final doc = await firestore.collection('venues').doc(trimmedId).get();
      return DataSuccess(mapVenueSnapshot(doc));
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueRepository] findById failed (${error.code}): '
          '${error.message}',
        );
      }
      return DataFailure(
        VexException('Failed to load venue.', code: error.code, cause: error),
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[FirebaseVenueRepository] findById failed: $error');
        debugPrint('$stackTrace');
      }
      return DataFailure(
        VexException(
          'Failed to load venue.',
          code: 'venue-load-failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<DataResult<Venue?>> watchById(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const DataSuccess(null));
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return Stream.value(
        DataFailure(
          const VexException(
            'Firebase is not initialized.',
            code: 'firebase-unavailable',
          ),
        ),
      );
    }

    return firestore
        .collection('venues')
        .doc(trimmedId)
        .snapshots()
        .map<DataResult<Venue?>>((doc) => DataSuccess(mapVenueSnapshot(doc)))
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, EventSink sink) {
              if (kDebugMode) {
                debugPrint(
                  '[FirebaseVenueRepository] watchById failed: $error',
                );
                debugPrint('$stackTrace');
              }
              sink.add(
                DataFailure(
                  VexException(
                    'Failed to watch venue.',
                    code: error is FirebaseException
                        ? error.code
                        : 'venue-watch-failed',
                    cause: error,
                  ),
                ),
              );
            },
          ),
        );
  }

  @visibleForTesting
  static bool isPublicVenueData(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['isDeleted'] == true) return false;
    if (data['searchablePublic'] == false) return false;
    if (data['isHidden'] == true) return false;
    if (data['publicVisible'] == false) return false;
    if (data['isVisible'] == false) return false;
    if (data['disabled'] == true) return false;

    final status = data['status']?.toString().trim().toLowerCase() ?? 'active';
    if (status == 'deleted' ||
        status == 'hidden' ||
        status == 'suspended' ||
        status == 'disabled') {
      return false;
    }

    return true;
  }

  @visibleForTesting
  static Venue? mapVenueSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) {
      if (kDebugMode) {
        debugPrint('[FirebaseVenueRepository] Venue not found: ${doc.id}');
      }
      return null;
    }

    return mapVenueEntry(doc.id, doc.data());
  }

  @visibleForTesting
  static Venue? mapVenueEntry(String id, Map<String, dynamic>? data) {
    if (!isPublicVenueData(data)) {
      return null;
    }

    try {
      return vexVenueFromVenueModel(VenueModel.fromMap(id, data!));
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueRepository] Malformed venue document $id: $error',
        );
      }
      return null;
    }
  }

  @visibleForTesting
  static List<Venue> mapVenueDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return mapVenueData(docs.map((doc) => MapEntry(doc.id, doc.data())));
  }

  @visibleForTesting
  static List<Venue> mapVenueData(
    Iterable<MapEntry<String, Map<String, dynamic>>> docs,
  ) {
    final venues = <Venue>[];
    for (final entry in docs) {
      final venue = mapVenueEntry(entry.key, entry.value);
      if (venue != null) {
        venues.add(venue);
      }
    }
    return venues;
  }
}
