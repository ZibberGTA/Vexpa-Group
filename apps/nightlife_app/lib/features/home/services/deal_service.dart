import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/shared/experience_search_term_builder.dart';

import '../models/deal_model.dart';

class DealService {
  DealService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<DealModel>> getReusableDealsForVenue(String venueId) {
    return _firestore
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final deals = snapshot.docs.map((doc) => DealModel.fromMap(doc.id, doc.data())).toList();
      deals.sort((a, b) => (a.effectiveEndDateTime ?? DateTime(2100)).compareTo(b.effectiveEndDateTime ?? DateTime(2100)));
      return deals;
    });
  }

  static Stream<List<DealModel>> getDealsForVenue(String venueId) {
    return _firestore
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final batch = _firestore.batch();
      var changed = false;
      final visible = <DealModel>[];
      for (final doc in snapshot.docs) {
        final deal = DealModel.fromMap(doc.id, doc.data());
        if (deal.isExpired && deal.isActive) {
          batch.update(doc.reference, {
            'isActive': false,
            'inactiveAt': FieldValue.serverTimestamp(),
          });
          changed = true;
        }
        if (deal.isCurrentlyVisible) visible.add(deal);
      }
      if (changed) {
        batch.commit().then((_) => rebuildVenueDealSearchTerms(venueId));
      }
      visible.sort((a, b) => (a.effectiveEndDateTime ?? DateTime(2100)).compareTo(b.effectiveEndDateTime ?? DateTime(2100)));
      return visible;
    });
  }


  static Future<void> deactivateExpiredDealsForVenue(String venueId) async {
    final snapshot = await _firestore
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    var changed = false;

    for (final doc in snapshot.docs) {
      final deal = DealModel.fromMap(doc.id, doc.data());
      if (deal.isExpired && deal.isActive) {
        batch.update(doc.reference, {
          'isActive': false,
          'inactiveAt': FieldValue.serverTimestamp(),
        });
        changed = true;
      }
    }

    if (changed) {
      await batch.commit();
      await rebuildVenueDealSearchTerms(venueId);
    }
  }

  static List<String> buildDealSearchTerms({
    required String title,
    required String description,
    String? startTime,
    String? endTime,
  }) {
    return ExperienceSearchTermBuilder.buildFromValues([
      title,
      description,
      if (startTime != null) startTime,
      if (endTime != null) endTime,
    ]);
  }

  static Future<void> addDealSearchTermsToVenue({
    required String venueId,
    required String title,
    required String description,
    String? startTime,
    String? endTime,
  }) async {
    final terms = buildDealSearchTerms(
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
    );

    await _firestore.collection('venues').doc(venueId).update({
      'searchTerms': FieldValue.arrayUnion(terms),
      'hasDeals': true,
    });
  }

  static Future<void> rebuildVenueDealSearchTerms(String venueId) async {
    final venueRef = _firestore.collection('venues').doc(venueId);

    final venueSnapshot = await venueRef.get();
    final venueData = venueSnapshot.data();

    if (venueData == null) return;

    final activeDeals = await _firestore
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .get();

    final baseTerms = <String>[
      venueData['name']?.toString() ?? '',
      venueData['category']?.toString() ?? '',
      venueData['address']?.toString() ?? '',
      venueData['crowdLevel']?.toString() ?? '',
    ];

    final dealTerms = <String>[];

    for (final doc in activeDeals.docs) {
      final dealModel = DealModel.fromMap(doc.id, doc.data());
      if (!dealModel.isCurrentlyVisible) continue;

      dealTerms.addAll(
        buildDealSearchTerms(
          title: dealModel.title,
          description: dealModel.description,
          startTime: dealModel.startTime,
          endTime: dealModel.endTime,
        ),
      );
    }

    final allTerms = <String>[
      ...baseTerms,
      ...dealTerms,
    ]
        .map((term) => term.trim().toLowerCase())
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();

    await venueRef.update({
      'searchTerms': allTerms,
      'hasDeals': dealTerms.isNotEmpty,
    });
  }
}