import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/venue_details_model.dart';

class VenueDetailsService {
  static final _firestore = FirebaseFirestore.instance;

  static Stream<VenueDetailsModel?> venueStream(String venueId) {
    return _firestore
        .collection('venues')
        .doc(venueId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return VenueDetailsModel.fromFirestore(doc);
    });
  }

  static Future<void> createVenue(VenueDetailsModel venue) async {
    await _firestore.collection('venues').add(venue.toFirestore());
  }

  static Future<void> updateVenue(VenueDetailsModel venue) async {
    await _firestore
        .collection('venues')
        .doc(venue.id)
        .update(venue.toFirestore());
  }
}