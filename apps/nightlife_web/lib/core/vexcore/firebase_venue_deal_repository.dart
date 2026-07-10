import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../core/firebase/vexda_firebase.dart';
import '../../features/venue/data/models/deal_model.dart';
import 'vex_venue_deal_mapper.dart';

/// Firebase adapter for public venue deal reads.
final class FirebaseVenueDealRepository implements VenueDealRepository {
  FirebaseVenueDealRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  @override
  Future<DataResult<List<VenueDeal>>> loadPublicDeals(String venueId) async {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return const DataSuccess([]);
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return const DataSuccess([]);
    }

    try {
      final snapshot = await firestore
          .collection('deals')
          .where('venueId', isEqualTo: trimmedId)
          .where('isDeleted', isEqualTo: false)
          .get();

      return DataSuccess(mapDealDocuments(snapshot.docs));
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueDealRepository] loadPublicDeals failed '
          '(${error.code}): ${error.message}',
        );
      }
      return DataFailure(
        VexException(
          error.message ?? 'Failed to load venue deals.',
          code: error.code,
          cause: error,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueDealRepository] loadPublicDeals failed: $error',
        );
        debugPrint('$stackTrace');
      }
      return DataFailure(
        VexException(
          'Failed to load venue deals.',
          code: 'venue-deal-load-failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<DataResult<List<VenueDeal>>> watchPublicDeals(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const DataSuccess([]));
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return Stream.value(const DataSuccess([]));
    }

    return firestore
        .collection('deals')
        .where('venueId', isEqualTo: trimmedId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map<DataResult<List<VenueDeal>>>(
          (snapshot) => DataSuccess(mapDealDocuments(snapshot.docs)),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, EventSink sink) {
              if (kDebugMode) {
                debugPrint(
                  '[FirebaseVenueDealRepository] watchPublicDeals failed: '
                  '$error',
                );
                debugPrint('$stackTrace');
              }
              sink.add(
                DataFailure(
                  VexException(
                    'Failed to watch venue deals.',
                    code: error is FirebaseException
                        ? error.code
                        : 'venue-deal-watch-failed',
                    cause: error,
                  ),
                ),
              );
            },
          ),
        );
  }

  @visibleForTesting
  static bool isPublicDealData(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['isDeleted'] == true) return false;
    if (data['isHidden'] == true) return false;
    if (data['isDraft'] == true) return false;
    if (data['publicVisible'] == false) return false;

    final status = data['status']?.toString().trim().toLowerCase();
    if (status == 'deleted' ||
        status == 'draft' ||
        status == 'hidden' ||
        status == 'suspended' ||
        status == 'disabled' ||
        status == 'inactive') {
      return false;
    }

    return true;
  }

  @visibleForTesting
  static VenueDeal? mapDealEntry(String id, Map<String, dynamic>? data) {
    if (!isPublicDealData(data)) {
      return null;
    }

    try {
      return vexVenueDealFromDealModel(DealModel.fromMap(id, data!));
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueDealRepository] Malformed deal document $id: $error',
        );
      }
      return null;
    }
  }

  @visibleForTesting
  static List<VenueDeal> mapDealDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return mapDealData(docs.map((doc) => MapEntry(doc.id, doc.data())));
  }

  @visibleForTesting
  static List<VenueDeal> mapDealData(
    Iterable<MapEntry<String, Map<String, dynamic>>> docs,
  ) {
    final deals = <VenueDeal>[];
    for (final entry in docs) {
      final deal = mapDealEntry(entry.key, entry.value);
      if (deal != null) {
        deals.add(deal);
      }
    }
    return deals;
  }
}
