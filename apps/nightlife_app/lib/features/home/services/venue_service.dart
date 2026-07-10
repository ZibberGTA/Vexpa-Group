import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/venue_model.dart';

class VenueService {
  VenueService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<VenueModel>> getVenues() {
  return _firestore
      .collection('venues')
      .where('isDeleted', isEqualTo: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => VenueModel.fromMap(doc.id, doc.data()))
        .toList();
  });
}

  static Stream<List<VenueModel>> getVenuesForOwner(String ownerId) {
  return _firestore
      .collection('venues')
      .where('ownerId', isEqualTo: ownerId)
      .where('isDeleted', isEqualTo: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => VenueModel.fromMap(doc.id, doc.data()))
        .toList();
  });
}
}