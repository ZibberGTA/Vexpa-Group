import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/discovery/shared/search_text_utils.dart';

import '../../../core/utils/public_venue_visibility.dart';
import '../../home/models/deal_model.dart';
import '../../home/models/venue_model.dart';

/// Firestore adapter for map discovery queries (venues, search, events).
class MapDiscoveryService {
  MapDiscoveryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Query<Map<String, dynamic>> get _publicVenuesQuery => _db
      .collection('venues')
      .where('isDeleted', isEqualTo: false);

  static List<QueryDocumentSnapshot<Map<String, dynamic>>>
      filterVisibleVenueDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .where((doc) => PublicVenueVisibility.isPublicMap(doc.data()))
        .toList();
  }

  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      watchPublicVenueSnapshots() {
    return _publicVenuesQuery.snapshots().map(
          (snapshot) => filterVisibleVenueDocuments(snapshot.docs),
        );
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      loadVenuesForSearch(String searchText) async {
    final query = searchText.trim().toLowerCase();

    if (query.isEmpty) {
      final snapshot = await _publicVenuesQuery.get();
      return filterVisibleVenueDocuments(snapshot.docs);
    }

    final terms = SearchTextUtils.termsFromQuery(query);
    if (terms.isEmpty) {
      final snapshot = await _publicVenuesQuery.get();
      return filterVisibleVenueDocuments(snapshot.docs);
    }

    final matchingVenueIds = <String>{};

    final venueSnapshot = await _publicVenuesQuery
        .where('searchTerms', arrayContainsAny: terms)
        .get();

    for (final doc in venueSnapshot.docs) {
      matchingVenueIds.add(doc.id);
    }

    final drinkSnapshot = await _db
        .collection('drinks')
        .where('isDeleted', isEqualTo: false)
        .where('available', isEqualTo: true)
        .where('searchTerms', arrayContainsAny: terms)
        .get();

    for (final doc in drinkSnapshot.docs) {
      final venueId = doc.data()['venueId']?.toString();
      if (venueId != null && venueId.isNotEmpty) {
        matchingVenueIds.add(venueId);
      }
    }

    final dealSnapshot = await _db
        .collection('deals')
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .where('searchTerms', arrayContainsAny: terms)
        .get();

    for (final doc in dealSnapshot.docs) {
      final deal = DealModel.fromMap(doc.id, doc.data());
      if (!deal.isCurrentlyVisible) continue;
      final venueId = doc.data()['venueId']?.toString();
      if (venueId != null && venueId.isNotEmpty) {
        matchingVenueIds.add(venueId);
      }
    }

    if (matchingVenueIds.isEmpty) {
      return [];
    }

    final venueDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final ids = matchingVenueIds.toList();

    for (var i = 0; i < ids.length; i += 10) {
      final batchIds = ids.skip(i).take(10).toList();

      final snapshot = await _publicVenuesQuery
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      venueDocs.addAll(snapshot.docs);
    }

    return filterVisibleVenueDocuments(venueDocs);
  }

  static Future<Set<String>> loadVenueIdsWithEventsTodayForVenueIds(
    List<String> venueIds,
  ) async {
    if (venueIds.isEmpty) return <String>{};

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final result = <String>{};

    for (var i = 0; i < venueIds.length; i += 10) {
      final batchIds = venueIds.skip(i).take(10).toList();
      if (batchIds.isEmpty) continue;

      final snapshot = await _db
          .collection('events')
          .where('venueId', whereIn: batchIds)
          .where(
            'dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
          )
          .where('dateTime', isLessThan: Timestamp.fromDate(startOfTomorrow))
          .where('isDeleted', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        final venueId = doc.data()['venueId']?.toString();
        if (venueId != null && venueId.isNotEmpty) {
          result.add(venueId);
        }
      }
    }

    return result;
  }

  static Future<VenueModel?> fetchVenueModel(String venueId) async {
    if (venueId.trim().isEmpty) return null;

    final doc = await _db.collection('venues').doc(venueId.trim()).get();
    if (!doc.exists) return null;

    return VenueModel.fromMap(doc.id, doc.data() ?? const {});
  }
}
