import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';

/// Builds Firestore payloads for mobile venue drink writes.
final class MobileDrinkWritePayload {
  MobileDrinkWritePayload._();

  static Map<String, dynamic> buildPresetCreate({
    required String venueId,
    required String venueName,
    required String drinkName,
    required String categoryDisplayName,
    double? price,
  }) {
    return {
      ...ExperienceOwnerWriteService.mobilePresetDrinkCreateFields(
        venueId: venueId,
        venueName: venueName,
        drinkName: drinkName,
        categoryDisplayName: categoryDisplayName,
        price: price,
      ),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> buildEditUpdate({
    required String name,
    required String category,
    required String price,
    required String description,
  }) {
    return {
      ...ExperienceOwnerWriteService.mobileDrinkEditFields(
        name: name,
        category: category,
        price: price,
        description: description,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
