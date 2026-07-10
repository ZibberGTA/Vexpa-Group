import 'package:cloud_firestore/cloud_firestore.dart';

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

    _addText(terms, venueData['name']);
    _addText(terms, venueData['description']);
    _addText(terms, venueData['address']);
    _addText(terms, venueData['category']);
    _addText(terms, venueData['crowdLevel']);

    for (final doc in drinksSnapshot.docs) {
      final data = doc.data();

      _addText(terms, data['name']);
      _addText(terms, data['category']);
      _addText(terms, data['description']);
      _addText(terms, data['price']);
      _addList(terms, data['keywords']);
    }

    for (final doc in dealsSnapshot.docs) {
      final data = doc.data();

      _addText(terms, data['title']);
      _addText(terms, data['description']);
      _addText(terms, data['startTime']);
      _addText(terms, data['endTime']);
      _addList(terms, data['keywords']);
    }

    if (dealsSnapshot.docs.isNotEmpty) {
      terms.addAll([
        'deal',
        'deals',
        'offer',
        'offers',
        'discount',
        'happy',
        'hour',
        'happy hour',
      ]);
    }

    await venueRef.update({
      'searchTerms': terms.toList(),
      'hasDeals': dealsSnapshot.docs.isNotEmpty,
    });
  }

  static void _addText(Set<String> terms, dynamic value) {
    if (value == null) return;

    final text = value.toString().toLowerCase().trim();
    if (text.isEmpty) return;

    terms.add(text);

    final words = text
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();

    terms.addAll(words);

    for (var i = 0; i < words.length - 1; i++) {
      terms.add('${words[i]} ${words[i + 1]}');
    }

    for (var i = 0; i < words.length - 2; i++) {
      terms.add('${words[i]} ${words[i + 1]} ${words[i + 2]}');
    }
  }

  static void _addList(Set<String> terms, dynamic list) {
    if (list is List) {
      for (final item in list) {
        _addText(terms, item);
      }
    }
  }
}