import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/vexcore/mobile_vexcore.dart';
import '../models/venue_details_model.dart';

class VenueDetailsService {
  static final _firestore = FirebaseFirestore.instance;

  static Stream<VenueDetailsModel?> venueStream(String venueId) {
    return MobileVexCore.venueRepository.watchVenueDetails(venueId);
  }

  static Future<void> createVenue(VenueDetailsModel venue) async {
    await _firestore.collection('venues').add(venue.toFirestore());
  }

  static Future<void> updateVenue(VenueDetailsModel venue) async {
    await _firestore.collection('venues').doc(venue.id).update(venue.toFirestore());
  }
}
