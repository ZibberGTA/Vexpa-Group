import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/discovery/shared/discovery_search_term_indexer.dart';

class SearchIndexService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> updateVenueSearchTerms(String venueId) async {
    final venueRef = _db.collection('venues').doc(venueId);
    final venueDoc = await venueRef.get();

    if (!venueDoc.exists) return;

    final venueData = venueDoc.data() ?? {};

    final drinksSnapshot = await _db
        .collection('drinks')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .get();

    final dealsSnapshot = await _db
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .get();

    final Set<String> terms = {};

    DiscoverySearchTermIndexer.addText(terms, venueData['name']);
    DiscoverySearchTermIndexer.addText(terms, venueData['description']);
    DiscoverySearchTermIndexer.addText(terms, venueData['address']);
    DiscoverySearchTermIndexer.addText(terms, venueData['category']);
    DiscoverySearchTermIndexer.addText(terms, venueData['crowdLevel']);

    for (final doc in drinksSnapshot.docs) {
      final data = doc.data();

      DiscoverySearchTermIndexer.addText(terms, data['name']);
      DiscoverySearchTermIndexer.addText(terms, data['category']);
      DiscoverySearchTermIndexer.addText(terms, data['description']);
      DiscoverySearchTermIndexer.addText(terms, data['price']);
      DiscoverySearchTermIndexer.addList(terms, data['keywords']);
    }

    for (final doc in dealsSnapshot.docs) {
      final data = doc.data();

      DiscoverySearchTermIndexer.addText(terms, data['title']);
      DiscoverySearchTermIndexer.addText(terms, data['description']);
      DiscoverySearchTermIndexer.addText(terms, data['startTime']);
      DiscoverySearchTermIndexer.addText(terms, data['endTime']);
      DiscoverySearchTermIndexer.addList(terms, data['keywords']);
    }

    if (dealsSnapshot.docs.isNotEmpty) {
      DiscoverySearchTermIndexer.addDealKeywords(terms);
    }

    await venueRef.update({
      'searchTerms': terms.toList(),
      'hasDeals': dealsSnapshot.docs.isNotEmpty,
    });
  }
}
