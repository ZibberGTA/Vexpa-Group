import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../core/firebase/vexda_firebase.dart';
import '../../features/venue/data/models/drink_model.dart';
import 'vex_venue_drink_mapper.dart';

/// Firebase adapter for public venue drink reads.
final class FirebaseVenueDrinkRepository implements VenueDrinkRepository {
  FirebaseVenueDrinkRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return _firestore ??= FirebaseFirestore.instance;
  }

  @override
  Future<DataResult<List<VenueDrink>>> loadPublicDrinks(String venueId) async {
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
          .collection('drinks')
          .where('venueId', isEqualTo: trimmedId)
          .where('isDeleted', isEqualTo: false)
          .get();

      return DataSuccess(mapDrinkDocuments(snapshot.docs));
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueDrinkRepository] loadPublicDrinks failed '
          '(${error.code}): ${error.message}',
        );
      }
      return DataFailure(
        VexException(
          error.message ?? 'Failed to load venue drinks.',
          code: error.code,
          cause: error,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueDrinkRepository] loadPublicDrinks failed: $error',
        );
        debugPrint('$stackTrace');
      }
      return DataFailure(
        VexException(
          'Failed to load venue drinks.',
          code: 'venue-drink-load-failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<DataResult<List<VenueDrink>>> watchPublicDrinks(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const DataSuccess([]));
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      return Stream.value(const DataSuccess([]));
    }

    return firestore
        .collection('drinks')
        .where('venueId', isEqualTo: trimmedId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map<DataResult<List<VenueDrink>>>(
          (snapshot) => DataSuccess(mapDrinkDocuments(snapshot.docs)),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, EventSink sink) {
              if (kDebugMode) {
                debugPrint(
                  '[FirebaseVenueDrinkRepository] watchPublicDrinks failed: '
                  '$error',
                );
                debugPrint('$stackTrace');
              }
              sink.add(
                DataFailure(
                  VexException(
                    'Failed to watch venue drinks.',
                    code: error is FirebaseException
                        ? error.code
                        : 'venue-drink-watch-failed',
                    cause: error,
                  ),
                ),
              );
            },
          ),
        );
  }

  @visibleForTesting
  static bool isPublicDrinkData(Map<String, dynamic>? data) {
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
  static VenueDrink? mapDrinkEntry(String id, Map<String, dynamic>? data) {
    if (!isPublicDrinkData(data)) {
      return null;
    }

    try {
      return vexVenueDrinkFromDrinkModel(DrinkModel.fromMap(id, data!));
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseVenueDrinkRepository] Malformed drink document $id: '
          '$error',
        );
      }
      return null;
    }
  }

  @visibleForTesting
  static List<VenueDrink> mapDrinkDocuments(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return mapDrinkData(docs.map((doc) => MapEntry(doc.id, doc.data())));
  }

  @visibleForTesting
  static List<VenueDrink> mapDrinkData(
    Iterable<MapEntry<String, Map<String, dynamic>>> docs,
  ) {
    final drinks = <VenueDrink>[];
    for (final entry in docs) {
      final drink = mapDrinkEntry(entry.key, entry.value);
      if (drink != null) {
        drinks.add(drink);
      }
    }
    return drinks;
  }
}
