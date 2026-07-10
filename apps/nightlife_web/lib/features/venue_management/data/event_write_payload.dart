import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vex_engines/experience/application/experience_scheduling_utils.dart';
import 'package:vex_engines/experience/application/experience_update_preparation.dart';

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
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();

    return {
      'venueId': venueId,
      'venueName': venueName,
      'title': trimmedTitle,
      'description': trimmedDescription,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'dateTime': Timestamp.fromDate(startDateTime),
      'category': category,
      'imageUrl': imageUrl,
      'isDeleted': false,
      'isActive': isActive,
      'featured': featured,
      'searchTerms': ExperienceUpdatePreparation.searchTermsForValues([
        trimmedTitle,
        trimmedDescription,
        venueName,
        category,
      ]),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
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
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };

    if (title != null) payload['title'] = title.trim();
    if (startDateTime != null) {
      payload['startDateTime'] = Timestamp.fromDate(startDateTime);
    }
    if (endDateTime != null) {
      payload['endDateTime'] = Timestamp.fromDate(endDateTime);
    }
    if (isActive != null) payload['isActive'] = isActive;
    if (featured != null) payload['featured'] = featured;

    return payload;
  }
}

DateTime mergeEventDate(DateTime existing, DateTime picked) =>
    ExperienceSchedulingUtils.mergeEventDate(existing, picked);

DateTime mergeEventTime(DateTime existing, String time) =>
    ExperienceSchedulingUtils.mergeEventTime(existing, time);
