import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';

/// Builds Firestore payloads for mobile venue deal writes.
final class MobileDealWritePayload {
  MobileDealWritePayload._();

  static Map<String, dynamic> buildCreate({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String startTime,
    required String endTime,
  }) {
    final fields = ExperienceOwnerWriteService.mobileDealCreateFields(
      venueId: venueId,
      venueName: venueName,
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      startTime: startTime,
      endTime: endTime,
    );

    return {
      ...fields,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> buildUpdate({
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String startTime,
    required String endTime,
  }) {
    final fields = ExperienceOwnerWriteService.mobileDealUpdateFields(
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      startTime: startTime,
      endTime: endTime,
    );

    return {
      ...fields,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
