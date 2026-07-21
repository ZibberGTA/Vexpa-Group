import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/vex_core.dart';
import 'package:vex_engines/experience/application/venue_presentation_support.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../../../core/vexcore/vex_venue_drink_mapper.dart';
import '../../../core/vexcore/web_vexcore.dart';
import '../../venue_management/data/drink_write_payload.dart';
import '../../venue_management/data/venue_management_activity_action_inference.dart';
import '../../venue_management/data/venue_management_activity_service.dart';
import '../../venue_management/models/bulk_drink_patch.dart';
import '../../venue_management/models/drink_categories.dart';
import '../../venue_management/models/drink_import_row.dart';
import '../../venue_management/models/venue_management_activity.dart';
import '../../venue_management/models/venue_management_activity_types.dart';
import 'models/drink_model.dart';

/// Loads and writes drinks for a venue.
class VenueDrinksRepository {
  VenueDrinksRepository({
    FirebaseFirestore? firestore,
    VenueDrinkDataService? venueDrinkDataService,
    VenueManagementActivityService? activityService,
  }) : _firestoreOverride = firestore,
       _venueDrinkDataService =
           venueDrinkDataService ?? WebVexCore.venueDrinkDataService,
       _activityService =
           activityService ?? WebVexCore.venueManagementActivityService;

  final FirebaseFirestore? _firestoreOverride;
  final VenueDrinkDataService _venueDrinkDataService;
  final VenueManagementActivityService _activityService;

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

  /// All non-deleted drinks for venue management (includes unavailable).
  Stream<List<DrinkModel>> watchManagementDrinks(String venueId) async* {
    final trimmedId = venueId.trim();
    if (trimmedId.isEmpty) {
      yield const [];
      return;
    }

    final firestore = _resolveFirestore();
    if (firestore == null) {
      yield const [];
      return;
    }

    yield* firestore
        .collection('drinks')
        .where('venueId', isEqualTo: trimmedId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final drinks =
              snapshot.docs
                  .map((doc) => DrinkModel.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort(
                  (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
          return drinks;
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
      await _recordDrinkActivity(
        venueId: venueId,
        drinkId: docRef.id,
        drinkName: name,
        actorUid: createdBy,
        actionType: VenueManagementActivityActionTypes.created,
        description: 'Drink created',
      );
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
    required String venueId,
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
      await _recordDrinkActivity(
        venueId: venueId,
        drinkId: drinkId,
        drinkName: name,
        actorUid: updatedBy,
        actionType: VenueManagementActivityActionTypes.updated,
        description: 'Drink updated',
      );
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
    String? venueId,
    String? drinkName,
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
      if (venueId != null &&
          venueId.trim().isNotEmpty &&
          drinkName != null &&
          drinkName.trim().isNotEmpty) {
        await _recordDrinkActivity(
          venueId: venueId,
          drinkId: drinkId,
          drinkName: drinkName,
          actorUid: deletedBy,
          actionType: VenueManagementActivityActionTypes.archived,
          description: 'Drink archived',
        );
      }
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
    required String venueId,
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
      final resolvedName = patch.name ?? drinkName;
      await _recordDrinkActivity(
        venueId: venueId,
        drinkId: drinkId,
        drinkName: resolvedName,
        actorUid: updatedBy,
        actionType: VenueManagementActivityActionInference.drinkPatchActionType(
          patch,
        ),
        description: patch.available != null
            ? 'Drink availability changed'
            : 'Drink updated',
      );
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
        venueId: drink.venueId,
        venueName: venueName,
        drinkName: drink.name,
        category: drink.category,
        patch: patch,
        updatedBy: updatedBy,
      );
    }
  }

  Future<void> bulkDeleteDrinks({
    required List<DrinkModel> drinks,
    required String deletedBy,
    String? deletedByEmail,
  }) async {
    for (final drink in drinks) {
      await deleteDrink(
        drinkId: drink.id,
        deletedBy: deletedBy,
        deletedByEmail: deletedByEmail,
        venueId: drink.venueId,
        drinkName: drink.name,
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
      final importedDrinks = <({String id, String name})>[];

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
        importedDrinks.add((id: docRef.id, name: drink.name));
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

      for (final drink in importedDrinks) {
        await _recordDrinkActivity(
          venueId: venueId,
          drinkId: drink.id,
          drinkName: drink.name,
          actorUid: createdBy,
          actionType: VenueManagementActivityActionTypes.created,
          description: 'Drink created',
        );
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

  static const _presentation = VenuePresentationSupport();

  static String relativeTimeLabel(DateTime date) =>
      _presentation.managementRelativeTimeLabel(date);

  Future<void> _recordDrinkActivity({
    required String venueId,
    required String drinkId,
    required String drinkName,
    required String actorUid,
    required String actionType,
    required String description,
  }) {
    return _activityService.recordActivity(
      VenueManagementActivity(
        venueId: venueId,
        sourceArea: VenueManagementActivitySourceAreas.drinks,
        actionType: actionType,
        entityType: VenueManagementActivityEntityTypes.drink,
        entityId: drinkId,
        entityName: drinkName,
        description: description,
        actorUid: actorUid,
      ),
    );
  }
}
