import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';

/// Builds Firestore payloads for mobile venue event writes.
final class MobileEventWritePayload {
  MobileEventWritePayload._();

  static Map<String, dynamic> buildCreate({
    required String venueId,
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String category,
    String imageUrl = '',
  }) {
    final fields = ExperienceOwnerWriteService.mobileEventCreateFields(
      venueId: venueId,
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      category: category,
      imageUrl: imageUrl,
    );

    return {
      ...fields,
      'dateTime': Timestamp.fromDate(startDateTime),
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'createdAt': Timestamp.now(),
    };
  }
}
