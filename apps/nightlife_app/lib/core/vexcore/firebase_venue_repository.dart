import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../features/home/models/venue_model.dart';
import '../../features/venues/models/venue_details_model.dart';
import 'mobile_venue_document_mapper.dart';

/// Firebase adapter for mobile public venue reads via VexCore contracts.
class FirebaseVenueRepository implements VenueRepository {
  FirebaseVenueRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  static const int catalogLoadLimit = 100;

  FirebaseFirestore get _db => _firestoreOverride ?? (_firestore ??= FirebaseFirestore.instance);

  Query<Map<String, dynamic>> get _catalogQuery =>
      _db.collection('venues').where('isDeleted', isEqualTo: false);

  @override
  Future<DataResult<List<Venue>>> loadPublicVenues() async {
    try {
      final snapshot = await _catalogQuery.limit(catalogLoadLimit).get();
      final venues = _mapVenueDocuments(snapshot.docs);
      return DataSuccess(venues);
    } on Object catch (error, stackTrace) {
      _logFailure('loadPublicVenues', error, stackTrace);
      return DataFailure(
        VexException(
          'Failed to load public venues.',
          code: error is FirebaseException ? error.code : 'venue-load-failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<DataResult<List<Venue>>> watchPublicVenues() {
    return _catalogQuery.snapshots().map<DataResult<List<Venue>>>((snapshot) {
      return DataSuccess(_mapVenueDocuments(snapshot.docs));
    }).transform(
      StreamTransformer.fromHandlers(
        handleError: (Object error, StackTrace stackTrace, EventSink sink) {
          _logFailure('watchPublicVenues', error, stackTrace);
          sink.add(
            DataFailure(
              VexException(
                'Failed to watch public venues.',
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

  /// Preserves full home [VenueModel] fields for existing mobile streams.
  Stream<List<VenueModel>> watchHomeVenueCatalog() {
    return _catalogQuery.snapshots().map((snapshot) {
      final venues = <VenueModel>[];
      for (final doc in snapshot.docs) {
        final venue = MobileVenueDocumentMapper.parseHomeVenueModel(
          doc.id,
          doc.data(),
        );
        if (venue != null) {
          venues.add(venue);
        }
      }
      return venues;
    });
  }

  Stream<VenueDetailsModel?> watchVenueDetails(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(null);
    }

    return _db.collection('venues').doc(trimmedId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MobileVenueDocumentMapper.parseVenueDetails(doc.id, doc.data());
    });
  }

  @override
  Future<DataResult<VenueSearchMatch>> searchPublicVenuesByTerms({
    required List<String> terms,
  }) async {
    if (terms.isEmpty) {
      return const DataSuccess(VenueSearchMatch(venueIds: {}));
    }

    try {
      final snapshot = await _catalogQuery
          .where('searchTerms', arrayContainsAny: terms)
          .get();
      return DataSuccess(
        VenueSearchMatch(venueIds: snapshot.docs.map((doc) => doc.id).toSet()),
      );
    } on Object catch (error, stackTrace) {
      _logFailure('searchPublicVenuesByTerms', error, stackTrace);
      return const DataSuccess(VenueSearchMatch(venueIds: {}));
    }
  }

  @override
  Future<DataResult<Venue?>> findById(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataSuccess(null);
    }

    try {
      final doc = await _db.collection('venues').doc(trimmedId).get();
      if (!doc.exists) {
        return const DataSuccess(null);
      }
      return DataSuccess(
        MobileVenueDocumentMapper.parseVexVenue(doc.id, doc.data()),
      );
    } on Object catch (error, stackTrace) {
      _logFailure('findById', error, stackTrace);
      return DataFailure(
        VexException(
          'Failed to load venue.',
          code: error is FirebaseException ? error.code : 'venue-load-failed',
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

    return _db.collection('venues').doc(trimmedId).snapshots().map((doc) {
      if (!doc.exists) {
        return const DataSuccess<Venue?>(null);
      }
      return DataSuccess(
        MobileVenueDocumentMapper.parseVexVenue(doc.id, doc.data()),
      );
    }).transform(
      StreamTransformer.fromHandlers(
        handleError: (Object error, StackTrace stackTrace, EventSink sink) {
          _logFailure('watchById', error, stackTrace);
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
  static List<Venue> mapVenueDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return _mapVenueDocuments(docs);
  }

  static List<Venue> _mapVenueDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final venues = <Venue>[];
    for (final doc in docs) {
      final venue = MobileVenueDocumentMapper.parseVexVenue(doc.id, doc.data());
      if (venue != null) {
        venues.add(venue);
      }
    }
    return venues;
  }

  void _logFailure(String label, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[FirebaseVenueRepository] $label failed: $error');
      debugPrint('$stackTrace');
    }
  }
}
