import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../venue/data/models/deal_model.dart';
import '../../venue/data/public_venue_content_filters.dart';
import '../../venue_management/data/deal_write_payload.dart';
import '../../venue_management/models/bulk_deal_patch.dart';
import '../../venue_management/models/deal_types.dart';

/// Loads and writes deals for a venue from Firestore.
class VenueDealsRepository {
  VenueDealsRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Stream<List<DealModel>> watchDeals(String venueId) async* {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      yield const [];
      return;
    }

    yield* firestore
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final deals = snapshot.docs
          .map((doc) => DealModel.fromMap(doc.id, doc.data()))
          .where((deal) => isPublicVisibleDeal(deal))
          .toList();

      deals.sort((a, b) {
        final aUpcoming = isPublicUpcomingDeal(a);
        final bUpcoming = isPublicUpcomingDeal(b);
        if (aUpcoming != bUpcoming) return aUpcoming ? 1 : -1;
        return (a.startDateTime ?? DateTime(2100))
            .compareTo(b.startDateTime ?? DateTime(2100));
      });

      return deals;
    });
  }

  /// All non-deleted deals for venue management (includes paused/expired).
  Stream<List<DealModel>> watchManagementDeals(String venueId) async* {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      yield const [];
      return;
    }

    yield* firestore
        .collection('deals')
        .where('venueId', isEqualTo: venueId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final deals = snapshot.docs
          .map((doc) => DealModel.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return deals;
    });
  }

  Future<String> addDeal({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required bool isActive,
    required bool featured,
    required String createdBy,
  }) async {
    if (!DealTypes.isAllowed(dealType)) {
      throw ArgumentError('Invalid deal type.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final docRef = firestore.collection('deals').doc();
    final payload = DealWritePayload.build(
      venueId: venueId,
      venueName: venueName,
      title: title,
      description: description,
      dealType: dealType,
      value: value,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      availableDays: availableDays,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
      featured: featured,
      createdBy: createdBy,
    );

    try {
      await docRef.set(payload);
      return docRef.id;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDealsRepository] add deal failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<String> duplicateDeal({
    required DealModel source,
    required String venueName,
    required String createdBy,
  }) async {
    final trimmedTitle = source.title.trim();
    final copyTitle = trimmedTitle.endsWith(' Copy')
        ? trimmedTitle
        : '$trimmedTitle Copy';

    return addDeal(
      venueId: source.venueId,
      venueName: venueName,
      title: copyTitle,
      description: source.description,
      dealType: source.dealType,
      value: source.value,
      startDateTime: source.startDateTime ?? DateTime.now(),
      endDateTime: source.endDateTime ??
          (source.startDateTime ?? DateTime.now()).add(const Duration(days: 30)),
      availableDays: source.availableDays,
      startTime: source.startTime,
      endTime: source.endTime,
      isActive: false,
      featured: false,
      createdBy: createdBy,
    );
  }

  Future<void> updateDeal({
    required String dealId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required bool isActive,
    required bool featured,
    required String updatedBy,
  }) async {
    if (!DealTypes.isAllowed(dealType)) {
      throw ArgumentError('Invalid deal type.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = DealWritePayload.buildUpdate(
      venueName: venueName,
      title: title,
      description: description,
      dealType: dealType,
      value: value,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      availableDays: availableDays,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
      featured: featured,
      updatedBy: updatedBy,
    );

    try {
      await firestore.collection('deals').doc(dealId).update(payload);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDealsRepository] update deal failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<void> deleteDeal({
    required String dealId,
    required String deletedBy,
    String? deletedByEmail,
  }) async {
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = <String, dynamic>{
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': deletedBy,
      if (deletedByEmail != null) 'deletedByEmail': deletedByEmail,
    };

    try {
      await firestore.collection('deals').doc(dealId).update(payload);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDealsRepository] delete deal failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<void> bulkDeleteDeals({
    required List<String> dealIds,
    required String deletedBy,
    String? deletedByEmail,
  }) async {
    for (final dealId in dealIds) {
      await deleteDeal(
        dealId: dealId,
        deletedBy: deletedBy,
        deletedByEmail: deletedByEmail,
      );
    }
  }

  Future<void> patchDeal({
    required String dealId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required BulkDealPatch patch,
    required String updatedBy,
  }) async {
    if (patch.isEmpty) return;

    if (patch.dealType != null && !DealTypes.isAllowed(patch.dealType!)) {
      throw ArgumentError('Invalid deal type.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = DealWritePayload.buildPatch(
      venueName: venueName,
      title: title,
      description: description,
      dealType: dealType,
      value: value,
      updatedBy: updatedBy,
      titlePatch: patch.title,
      dealTypePatch: patch.dealType,
      valuePatch: patch.value,
      startDateTime: patch.startDateTime,
      endDateTime: patch.endDateTime,
      isActive: patch.isActive,
      featured: patch.featured,
    );

    try {
      await firestore.collection('deals').doc(dealId).update(payload);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDealsRepository] patch deal failed (${error.code})');
      }
      rethrow;
    }
  }

  static String relativeTimeLabel(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
