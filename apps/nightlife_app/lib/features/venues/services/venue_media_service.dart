import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/venue_media_model.dart';

/// Loads venue-owned media for profile/gallery/deal/event views.
///
/// Venue cards should continue using denormalized fields on the venue document
/// for performance; call this only when a venue profile is opened.
class VenueMediaService {
  VenueMediaService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<VenueMediaBundle> watchPublicMedia(String venueId) {
    return _firestore
        .collection('venues')
        .doc(venueId)
        .collection('media')
        .where('visible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(VenueMediaModel.fromDoc)
          .where((item) => item.venueId == venueId)
          .toList();
      return VenueMediaBundle.fromItems(items);
    });
  }

  Future<VenueMediaBundle> fetchPublicMedia(String venueId) async {
    final snapshot = await _firestore
        .collection('venues')
        .doc(venueId)
        .collection('media')
        .where('visible', isEqualTo: true)
        .get();

    final items = snapshot.docs
        .map(VenueMediaModel.fromDoc)
        .where((item) => item.venueId == venueId)
        .toList();
    return VenueMediaBundle.fromItems(items);
  }
}
