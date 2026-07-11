import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/discovery/shared/discovery_venue_search_term_builder.dart';

class VenueSearchSyncService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> syncVenueSearchTerms(String venueId) async {
    final venueDoc = await _db.collection('venues').doc(venueId).get();
    if (!venueDoc.exists) return;

    final venueData = venueDoc.data()!;

    final name = (venueData['name'] ?? '').toString();
    final category = (venueData['category'] ?? '').toString();
    final address = (venueData['address'] ?? '').toString();
    final description = (venueData['description'] ?? '').toString();

    final drinksSnapshot = await _db
        .collection('drinks')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .get();

    final drinkNames = drinksSnapshot.docs
        .map((d) => (d.data()['name'] ?? '').toString())
        .toList();

    final terms = DiscoveryVenueSearchTermBuilder.buildFromFirestoreVenueSync(
      name: name,
      category: category,
      address: address,
      description: description,
      drinkNames: drinkNames,
    );

    await _db.collection('venues').doc(venueId).update({
      'searchTerms': terms,
      'hasDeals': false,
    });
  }
}
