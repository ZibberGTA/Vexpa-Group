import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vex_engines/experience/application/experience_update_preparation.dart';

import '../models/drink_categories.dart';

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
    final normalizedCategory = DrinkCategories.normalize(category);
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();

    return {
      'venueId': venueId,
      'venueName': venueName,
      'name': trimmedName,
      'category': normalizedCategory,
      'price': price,
      'description': trimmedDescription,
      'available': available,
      'featured': featured,
      'isDeleted': false,
      'searchTerms': ExperienceUpdatePreparation.searchTermsForValues([
        trimmedName,
        DrinkCategories.displayName(normalizedCategory),
        venueName,
      ]),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
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
    final normalizedCategory = DrinkCategories.normalize(category);
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();

    return {
      'name': trimmedName,
      'category': normalizedCategory,
      'price': price,
      'description': trimmedDescription,
      'available': available,
      'featured': featured,
      'searchTerms': ExperienceUpdatePreparation.searchTermsForValues([
        trimmedName,
        DrinkCategories.displayName(normalizedCategory),
        venueName,
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
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
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };

    final effectiveName = name?.trim() ?? drinkName.trim();
    final effectiveCategory =
        categoryPatch == null ? category : DrinkCategories.normalize(categoryPatch);

    if (name != null) payload['name'] = effectiveName;
    if (categoryPatch != null) {
      payload['category'] = effectiveCategory;
    }
    if (price != null) payload['price'] = price;
    if (available != null) payload['available'] = available;
    if (featured != null) payload['featured'] = featured;

    if (name != null || categoryPatch != null) {
      payload['searchTerms'] = ExperienceUpdatePreparation.searchTermsForValues([
        effectiveName,
        DrinkCategories.displayName(effectiveCategory),
        venueName,
      ]);
    }

    return payload;
  }
}
