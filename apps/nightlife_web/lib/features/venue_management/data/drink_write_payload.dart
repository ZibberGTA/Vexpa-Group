import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_write_preparation.dart';

/// Builds Firestore payloads for venue drink writes.
class DrinkWritePayload {
  DrinkWritePayload._();

  static Map<String, dynamic> build({
    required String venueId,
    required String venueName,
    required String name,
    required String category,
    required String description,
    required bool available,
    required bool featured,
    required String createdBy,
    double? price,
  }) {
    return {
      ...ExperienceWritePreparation.drinkCreateFields(
        venueId: venueId,
        venueName: venueName,
        name: name,
        category: category,
        description: description,
        available: available,
        featured: featured,
        createdBy: createdBy,
        price: price,
      ),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> buildUpdate({
    required String venueName,
    required String name,
    required String category,
    required String description,
    required bool available,
    required bool featured,
    required String updatedBy,
    double? price,
  }) {
    return {
      ...ExperienceWritePreparation.drinkUpdateFields(
        venueName: venueName,
        name: name,
        category: category,
        description: description,
        available: available,
        featured: featured,
        updatedBy: updatedBy,
        price: price,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> buildPatch({
    required String venueName,
    required String drinkName,
    required String category,
    required String updatedBy,
    String? name,
    String? categoryPatch,
    double? price,
    bool? available,
    bool? featured,
  }) {
    return {
      ...ExperienceWritePreparation.drinkPatchFields(
        venueName: venueName,
        drinkName: drinkName,
        category: category,
        updatedBy: updatedBy,
        name: name,
        categoryPatch: categoryPatch,
        price: price,
        available: available,
        featured: featured,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
