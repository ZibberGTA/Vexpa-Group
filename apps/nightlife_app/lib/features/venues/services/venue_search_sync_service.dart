import 'package:cloud_firestore/cloud_firestore.dart';

class VenueSearchSyncService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> syncVenueSearchTerms(String venueId) async {
    // 1. Get venue
    final venueDoc = await _db.collection('venues').doc(venueId).get();
    if (!venueDoc.exists) return;

    final venueData = venueDoc.data()!;

    final name = (venueData['name'] ?? '').toString();
    final category = (venueData['category'] ?? '').toString();
    final address = (venueData['address'] ?? '').toString();
    final description = (venueData['description'] ?? '').toString();

    // 2. Get drinks
    final drinksSnapshot = await _db
        .collection('drinks')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .get();

    final drinkNames = drinksSnapshot.docs
        .map((d) => (d.data()['name'] ?? '').toString())
        .toList();

    // 3. Build search terms
    final terms = <String>{};

    void add(String value) {
      final v = value.toLowerCase().trim();
      if (v.isEmpty) return;

      terms.add(v);

      final parts = v.split(RegExp(r'[\s\-/_,.&]+'));
      for (final p in parts) {
        if (p.trim().isNotEmpty) {
          terms.add(p.trim());
        }
      }
    }

    add(name);
    add(category);
    add(address);
    add(description);

    for (final drink in drinkNames) {
      add(drink);
    }

    // whisky/whiskey alias
    if (terms.contains('whisky')) terms.add('whiskey');
    if (terms.contains('whiskey')) terms.add('whisky');

    // 4. Save
    await _db.collection('venues').doc(venueId).update({
      'searchTerms': terms.toList(),
      'hasDeals': false, // update later when deals exist
    });
  }
}