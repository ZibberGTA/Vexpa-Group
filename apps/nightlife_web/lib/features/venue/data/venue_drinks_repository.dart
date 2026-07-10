import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../../core/vexcore/vex_venue_drink_mapper.dart';
import '../../../core/vexcore/web_vexcore.dart';
import '../../venue_management/data/drink_write_payload.dart';
import '../../venue_management/models/bulk_drink_patch.dart';
import '../../venue_management/models/drink_categories.dart';
import '../../venue_management/models/drink_import_row.dart';
import 'models/drink_model.dart';

/// Loads and writes drinks for a venue.
class VenueDrinksRepository {
  VenueDrinksRepository({
    FirebaseFirestore? firestore,
    VenueDrinkDataService? venueDrinkDataService,
  }) : _firestoreOverride = firestore,
       _venueDrinkDataService =
           venueDrinkDataService ?? WebVexCore.venueDrinkDataService;

  final FirebaseFirestore? _firestoreOverride;
  final VenueDrinkDataService _venueDrinkDataService;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Stream<List<DrinkModel>> watchDrinks(String venueId) {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      return Stream.value(const []);
    }

    return _venueDrinkDataService.watchPublicDrinks(trimmedId).map((result) {
      return switch (result) {
        DataSuccess(:final value) =>
          value.map(drinkModelFromVexVenueDrink).toList(),
        DataFailure(:final error) => throw error,
      };
    });
  }

  Future<String> addDrink({
    required String venueId,
    required String venueName,
    required String name,
    required String category,
    required String description,
    required bool available,
    required bool featured,
    required String createdBy,
    double? price,
  }) async {
    if (!DrinkCategories.isAllowed(category)) {
      throw ArgumentError('Invalid drink category.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final docRef = firestore.collection('drinks').doc();
    final payload = DrinkWritePayload.build(
      venueId: venueId,
      venueName: venueName,
      name: name,
      category: category,
      description: description,
      available: available,
      featured: featured,
      createdBy: createdBy,
      price: price,
    );

    try {
      await docRef.set(payload);
      return docRef.id;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[VenueDrinksRepository] add drink failed (${error.code})');
      }
      rethrow;
    }
  }

  Future<void> updateDrink({
    required String drinkId,
    required String venueName,
    required String name,
    required String category,
    required String description,
    required bool available,
    required bool featured,
    required String updatedBy,
    double? price,
  }) async {
    if (!DrinkCategories.isAllowed(category)) {
      throw ArgumentError('Invalid drink category.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = DrinkWritePayload.buildUpdate(
      venueName: venueName,
      name: name,
      category: category,
      description: description,
      available: available,
      featured: featured,
      updatedBy: updatedBy,
      price: price,
    );

    try {
      await firestore.collection('drinks').doc(drinkId).update(payload);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[VenueDrinksRepository] update drink failed (${error.code})',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteDrink({
    required String drinkId,
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
      'deletedByEmail': ?deletedByEmail,
    };

    try {
      await firestore.collection('drinks').doc(drinkId).update(payload);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[VenueDrinksRepository] delete drink failed (${error.code})',
        );
      }
      rethrow;
    }
  }

  Future<void> patchDrink({
    required String drinkId,
    required String venueName,
    required String drinkName,
    required String category,
    required BulkDrinkPatch patch,
    required String updatedBy,
  }) async {
    if (patch.isEmpty) return;

    if (patch.category != null && !DrinkCategories.isAllowed(patch.category!)) {
      throw ArgumentError('Invalid drink category.');
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    final payload = DrinkWritePayload.buildPatch(
      venueName: venueName,
      drinkName: drinkName,
      category: category,
      updatedBy: updatedBy,
      name: patch.name,
      categoryPatch: patch.category,
      price: patch.price,
      available: patch.available,
      featured: patch.featured,
    );

    try {
      await firestore.collection('drinks').doc(drinkId).update(payload);
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[VenueDrinksRepository] patch drink failed (${error.code})',
        );
      }
      rethrow;
    }
  }

  Future<void> bulkPatchDrinks({
    required List<DrinkModel> drinks,
    required String venueName,
    required BulkDrinkPatch patch,
    required String updatedBy,
  }) async {
    for (final drink in drinks) {
      await patchDrink(
        drinkId: drink.id,
        venueName: venueName,
        drinkName: drink.name,
        category: drink.category,
        patch: patch,
        updatedBy: updatedBy,
      );
    }
  }

  Future<void> bulkDeleteDrinks({
    required List<String> drinkIds,
    required String deletedBy,
    String? deletedByEmail,
  }) async {
    for (final drinkId in drinkIds) {
      await deleteDrink(
        drinkId: drinkId,
        deletedBy: deletedBy,
        deletedByEmail: deletedByEmail,
      );
    }
  }

  Future<int> bulkImportDrinks({
    required String venueId,
    required String venueName,
    required List<DrinkImportCommitRow> drinks,
    required String createdBy,
  }) async {
    if (drinks.isEmpty) return 0;

    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore is not available.');
    }

    for (final drink in drinks) {
      if (!DrinkCategories.isAllowed(drink.category)) {
        throw ArgumentError('Invalid drink category.');
      }
    }

    try {
      var batch = firestore.batch();
      var writesInBatch = 0;
      var importedCount = 0;

      for (final drink in drinks) {
        final docRef = firestore.collection('drinks').doc();
        batch.set(
          docRef,
          DrinkWritePayload.build(
            venueId: venueId,
            venueName: venueName,
            name: drink.name,
            category: drink.category,
            description: '',
            available: drink.available,
            featured: drink.featured,
            createdBy: createdBy,
            price: drink.price,
          ),
        );
        writesInBatch++;
        importedCount++;

        if (writesInBatch >= 450) {
          await batch.commit();
          batch = firestore.batch();
          writesInBatch = 0;
        }
      }

      if (writesInBatch > 0) {
        await batch.commit();
      }

      return importedCount;
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[VenueDrinksRepository] bulk import failed (${error.code})',
        );
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
