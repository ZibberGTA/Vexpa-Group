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

  @visibleForTesting
  static List<Venue> mapVenueDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return mapVenueData(
      docs.map((doc) => MapEntry(doc.id, doc.data())),
    );
  }

  @visibleForTesting
  static List<Venue> mapVenueData(
    Iterable<MapEntry<String, Map<String, dynamic>>> docs,
  ) {
    return docs
        .map(
          (entry) => vexVenueFromVenueModel(
            VenueModel.fromMap(entry.key, entry.value),
          ),
        )
        .toList();
  }
}
