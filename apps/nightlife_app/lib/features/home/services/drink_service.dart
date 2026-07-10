
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/drink_model.dart';

class DrinkService {
  DrinkService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<DrinkModel>> getDrinksForVenue(String venueId) {
  return _firestore
      .collection('drinks')
      .where('venueId', isEqualTo: venueId)
      .where('isDeleted', isEqualTo: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => DrinkModel.fromMap(doc.id, doc.data()))
        .toList();
  });
}
}