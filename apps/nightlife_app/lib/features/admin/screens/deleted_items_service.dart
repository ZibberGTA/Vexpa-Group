import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/discovery/shared/discovery_venue_search_term_builder.dart';

class DeletedItemsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _deletedItems =>
      _firestore.collection('deleted_items');

  static List<String> _buildSearchTerms(Map<String, dynamic> data) {
    return DiscoveryVenueSearchTermBuilder.buildFromFieldValues([
      data['venueName']?.toString() ?? '',
      data['name']?.toString() ?? '',
      data['title']?.toString() ?? '',
      data['description']?.toString() ?? '',
      data['category']?.toString() ?? '',
      data['address']?.toString() ?? '',
      data['startTime']?.toString() ?? '',
      data['endTime']?.toString() ?? '',
      data['price']?.toString() ?? '',
      data['deletedByEmail']?.toString() ?? '',
    ]);
  }

  static Future<void> _syncVenueHasDeals(String venueId) async {
    if (venueId.isEmpty || venueId == 'unknown-venue') return;

    final activeDeals = await _firestore
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    await _firestore.collection('venues').doc(venueId).update({
      'hasDeals': activeDeals.docs.isNotEmpty,
    });
  }

  static Future<void> upsertDeletedItem({
    required String sourceCollection,
    required String sourceDocId,
    required Map<String, dynamic> sourceData,
  }) async {
    final itemType = sourceCollection == 'venues'
        ? 'venue'
        : sourceCollection == 'drinks'
            ? 'drink'
            : 'deal';

    final title = sourceCollection == 'venues'
        ? (sourceData['name']?.toString() ?? 'Untitled Venue')
        : sourceCollection == 'drinks'
            ? (sourceData['name']?.toString() ?? 'Untitled Drink')
            : (sourceData['title']?.toString() ?? 'Untitled Deal');

    final subtitle = sourceCollection == 'venues'
        ? ((sourceData['description'] ?? sourceData['address'] ?? 'No details')
            .toString())
        : sourceCollection == 'drinks'
            ? '${sourceData['category'] ?? ''} • ${sourceData['description'] ?? 'No details'}'
            : '${sourceData['description'] ?? 'No details'}\n${sourceData['startTime'] ?? ''} - ${sourceData['endTime'] ?? ''}';

    final venueId = sourceCollection == 'venues'
        ? sourceDocId
        : (sourceData['venueId']?.toString() ?? 'unknown-venue');

    final venueName = sourceCollection == 'venues'
        ? (sourceData['name']?.toString() ?? 'Unknown Venue')
        : (sourceData['venueName']?.toString() ?? 'Unknown Venue');

    await _deletedItems.doc('${sourceCollection}_$sourceDocId').set({
      'sourceCollection': sourceCollection,
      'sourceDocId': sourceDocId,
      'venueId': venueId,
      'venueName': venueName,
      'title': title,
      'subtitle': subtitle,
      'itemType': itemType,
      'deletedAt': sourceData['deletedAt'] ?? FieldValue.serverTimestamp(),
      'deletedBy': sourceData['deletedBy'],
      'deletedByEmail': sourceData['deletedByEmail'],
      'searchTerms': _buildSearchTerms(sourceData),
    });
  }

  static Future<void> removeDeletedItem({
    required String sourceCollection,
    required String sourceDocId,
  }) async {
    await _deletedItems.doc('${sourceCollection}_$sourceDocId').delete();
  }

  static Future<void> markDeleted({
    required String collection,
    required String docId,
    required String deletedBy,
    required String deletedByEmail,
  }) async {
    final docRef = _firestore.collection(collection).doc(docId);
    String? affectedVenueId;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('Document not found.');
      }

      final data = snapshot.data() as Map<String, dynamic>;

      transaction.update(docRef, {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': deletedBy,
        'deletedByEmail': deletedByEmail,
      });

      final merged = Map<String, dynamic>.from(data)
        ..addAll({
          'isDeleted': true,
          'deletedBy': deletedBy,
          'deletedByEmail': deletedByEmail,
          'deletedAt': Timestamp.now(),
        });

      final itemType = collection == 'venues'
          ? 'venue'
          : collection == 'drinks'
              ? 'drink'
              : 'deal';

      final title = collection == 'venues'
          ? (merged['name']?.toString() ?? 'Untitled Venue')
          : collection == 'drinks'
              ? (merged['name']?.toString() ?? 'Untitled Drink')
              : (merged['title']?.toString() ?? 'Untitled Deal');

      final subtitle = collection == 'venues'
          ? ((merged['description'] ?? merged['address'] ?? 'No details')
              .toString())
          : collection == 'drinks'
              ? '${merged['category'] ?? ''} • ${merged['description'] ?? 'No details'}'
              : '${merged['description'] ?? 'No details'}\n${merged['startTime'] ?? ''} - ${merged['endTime'] ?? ''}';

      final venueId = collection == 'venues'
          ? docId
          : (merged['venueId']?.toString() ?? 'unknown-venue');

      affectedVenueId = venueId;

      final venueName = collection == 'venues'
          ? (merged['name']?.toString() ?? 'Unknown Venue')
          : (merged['venueName']?.toString() ?? 'Unknown Venue');

      transaction.set(
        _deletedItems.doc('${collection}_$docId'),
        {
          'sourceCollection': collection,
          'sourceDocId': docId,
          'venueId': venueId,
          'venueName': venueName,
          'title': title,
          'subtitle': subtitle,
          'itemType': itemType,
          'deletedAt': Timestamp.now(),
          'deletedBy': deletedBy,
          'deletedByEmail': deletedByEmail,
          'searchTerms': _buildSearchTerms(merged),
        },
      );
    });

    final venueIdToSync = affectedVenueId;

    if (collection == 'deals' && venueIdToSync != null) {
      await _syncVenueHasDeals(venueIdToSync);
    }
  }

  static Future<void> restoreItem({
    required String collection,
    required String docId,
  }) async {
    final docRef = _firestore.collection(collection).doc(docId);
    final deletedRef = _deletedItems.doc('${collection}_$docId');

    String? affectedVenueId;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>?;

      affectedVenueId = collection == 'venues'
          ? docId
          : data?['venueId']?.toString();

      transaction.update(docRef, {
        'isDeleted': false,
        'deletedAt': null,
        'deletedBy': null,
        'deletedByEmail': null,
      });

      transaction.delete(deletedRef);
    });

    final venueIdToSync = affectedVenueId;

    if (collection == 'deals' && venueIdToSync != null) {
      await _syncVenueHasDeals(venueIdToSync);
    }
  }

  static Future<void> permanentlyDeleteItem({
    required String collection,
    required String docId,
  }) async {
    final docRef = _firestore.collection(collection).doc(docId);
    final deletedRef = _deletedItems.doc('${collection}_$docId');

    String? affectedVenueId;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>?;

      affectedVenueId = collection == 'venues'
          ? docId
          : data?['venueId']?.toString();

      transaction.delete(docRef);
      transaction.delete(deletedRef);
    });

    final venueIdToSync = affectedVenueId;

    if (collection == 'deals' && venueIdToSync != null) {
      await _syncVenueHasDeals(venueIdToSync);
    }
  }

  static Future<void> restoreVenueGroup({
    required String venueId,
  }) async {
    final batch = _firestore.batch();

    final deletedItemsSnapshot =
        await _deletedItems.where('venueId', isEqualTo: venueId).get();

    bool restoredDeal = false;

    for (final doc in deletedItemsSnapshot.docs) {
      final data = doc.data();
      final sourceCollection = data['sourceCollection']?.toString();
      final sourceDocId = data['sourceDocId']?.toString();

      if (sourceCollection == null || sourceDocId == null) continue;

      if (sourceCollection == 'deals') {
        restoredDeal = true;
      }

      final sourceRef = _firestore.collection(sourceCollection).doc(sourceDocId);

      batch.update(sourceRef, {
        'isDeleted': false,
        'deletedAt': null,
        'deletedBy': null,
        'deletedByEmail': null,
      });

      batch.delete(doc.reference);
    }

    await batch.commit();

    if (restoredDeal) {
      await _syncVenueHasDeals(venueId);
    }
  }

  static Future<void> permanentlyDeleteVenueGroup({
    required String venueId,
  }) async {
    final batch = _firestore.batch();

    final deletedItemsSnapshot =
        await _deletedItems.where('venueId', isEqualTo: venueId).get();

    bool deletedDeal = false;

    for (final doc in deletedItemsSnapshot.docs) {
      final data = doc.data();
      final sourceCollection = data['sourceCollection']?.toString();
      final sourceDocId = data['sourceDocId']?.toString();

      if (sourceCollection == null || sourceDocId == null) continue;

      if (sourceCollection == 'deals') {
        deletedDeal = true;
      }

      final sourceRef = _firestore.collection(sourceCollection).doc(sourceDocId);

      batch.delete(sourceRef);
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (deletedDeal) {
      await _syncVenueHasDeals(venueId);
    }
  }
}