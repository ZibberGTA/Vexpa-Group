import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../venues/models/venue_model.dart';
import '../models/venue_details_view.dart';
import 'venue_details_mapper.dart';

/// Loads a single venue document from Firestore for the details page.
class VenueDetailsRepository {
  VenueDetailsRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Future<VenueDetailsView?> loadVenue(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return null;

    final firestore = _resolveFirestore();
    if (firestore == null) {
      if (kDebugMode) {
        debugPrint('[VenueDetailsRepository] Firebase not initialized.');
      }
      return null;
    }

    try {
      final doc = await firestore.collection('venues').doc(trimmedId).get();

      return _mapVenueDoc(doc);
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[VenueDetailsRepository] Failed to load venue: $error');
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  /// Live venue stream for public profile — logo/banner update without reload.
  Stream<VenueDetailsView?> watchVenue(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) return Stream.value(null);

    final firestore = _resolveFirestore();
    if (firestore == null) {
      if (kDebugMode) {
        debugPrint('[VenueDetailsRepository] Firebase not initialized.');
      }
      return Stream.value(null);
    }

    return firestore
        .collection('venues')
        .doc(trimmedId)
        .snapshots()
        .map(_mapVenueDoc);
  }

  VenueDetailsView? _mapVenueDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) {
      if (kDebugMode) {
        debugPrint('[VenueDetailsRepository] Venue not found: ${doc.id}');
      }
      return null;
    }

    final data = doc.data();
    if (data == null || data['isDeleted'] == true) {
      return null;
    }

    final venue = VenueModel.fromMap(doc.id, data);
    return VenueDetailsMapper.fromVenueModel(venue);
  }
}
