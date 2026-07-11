import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_scheduling_utils.dart';
import 'package:vex_engines/experience/application/experience_write_preparation.dart';

/// Builds Firestore payloads for venue event writes.
class EventWritePayload {
  EventWritePayload._();

  static Map<String, dynamic> build({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool isActive,
    required bool featured,
    required String createdBy,
    String category = 'General',
    String imageUrl = '',
  }) {
    final fields = ExperienceWritePreparation.eventCreateFields(
      venueId: venueId,
      venueName: venueName,
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isActive: isActive,
      featured: featured,
      createdBy: createdBy,
      category: category,
      imageUrl: imageUrl,
    );

    return {
      ...fields,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'dateTime': Timestamp.fromDate(startDateTime),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> buildPatch({
    required String updatedBy,
    String? title,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isActive,
    bool? featured,
  }) {
    final fields = ExperienceWritePreparation.eventPatchFields(
      updatedBy: updatedBy,
      title: title,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isActive: isActive,
      featured: featured,
    );

    if (startDateTime != null) {
      fields['startDateTime'] = Timestamp.fromDate(startDateTime);
      fields['dateTime'] = Timestamp.fromDate(startDateTime);
    }
    if (endDateTime != null) {
      fields['endDateTime'] = Timestamp.fromDate(endDateTime);
    }

    return {
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

DateTime mergeEventDate(DateTime existing, DateTime picked) =>
    ExperienceSchedulingUtils.mergeEventDate(existing, picked);

DateTime mergeEventTime(DateTime existing, String time) =>
    ExperienceSchedulingUtils.mergeEventTime(existing, time);
