import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/admin_claim_venue.dart';

class AdminClaimVenueLoadResult {
  const AdminClaimVenueLoadResult({
    required this.venues,
    required this.totalRecords,
    required this.mappedRecords,
    required this.missingCoordinates,
  });

  final List<AdminClaimVenue> venues;
  final int totalRecords;
  final int mappedRecords;
  final int missingCoordinates;
}

class AdminClaimVenueRepository {
  AdminClaimVenueRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  static const collectionPath = 'venue_claim_directory';
  static const _pageSize = 1000;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  Future<AdminClaimVenueLoadResult> loadClaimVenues() async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firebase is not initialized.');
    }

    final venues = <AdminClaimVenue>[];
    var totalRecords = 0;
    var missingCoordinates = 0;
    DocumentSnapshot<Map<String, dynamic>>? lastDocument;
    var page = 0;

    while (true) {
      page++;
      Query<Map<String, dynamic>> query = firestore
          .collection(collectionPath)
          .orderBy(FieldPath.documentId)
          .limit(_pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      try {
        final snapshot = await query.get();
        if (snapshot.docs.isEmpty) break;

        totalRecords += snapshot.docs.length;
        lastDocument = snapshot.docs.last;

        for (final doc in snapshot.docs) {
          try {
            final venue = AdminClaimVenue.fromFirestore(doc);
            if (venue.hasValidCoordinates) {
              venues.add(venue);
            } else {
              missingCoordinates++;
            }
          } on Object catch (error, stackTrace) {
            missingCoordinates++;
            if (kDebugMode) {
              debugPrint(
                '[AdminClaimVenueRepository] parse failed '
                'collection=$collectionPath doc=${doc.id} error=$error',
              );
              debugPrint('$stackTrace');
            }
          }
        }

        if (snapshot.docs.length < _pageSize) break;
      } on FirebaseException catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[AdminClaimVenueRepository] load failed '
            'collection=$collectionPath page=$page code=${error.code} '
            'message=${error.message}',
          );
          debugPrint('$stackTrace');
        }
        rethrow;
      }
    }

    venues.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (kDebugMode) {
      debugPrint(
        '[AdminClaimVenueRepository] loaded collection=$collectionPath '
        'total=$totalRecords mapped=${venues.length} '
        'missingCoordinates=$missingCoordinates',
      );
    }

    return AdminClaimVenueLoadResult(
      venues: venues,
      totalRecords: totalRecords,
      mappedRecords: venues.length,
      missingCoordinates: missingCoordinates,
    );
  }
}
