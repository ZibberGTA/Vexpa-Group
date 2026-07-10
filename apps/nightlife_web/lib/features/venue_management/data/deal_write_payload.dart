import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vex_engines/experience/application/experience_scheduling_utils.dart';
import 'package:vex_engines/experience/application/experience_update_preparation.dart';

import '../models/deal_types.dart';

/// Builds Firestore payloads for venue deal writes.
class DealWritePayload {
  DealWritePayload._();

  static Map<String, dynamic> build({
    required String venueId,
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required bool isActive,
    required bool featured,
    required String createdBy,
  }) {
    final normalizedType = DealTypes.normalize(dealType);
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    final trimmedValue = value.trim();

    return {
      'venueId': venueId,
      'venueName': venueName,
      'title': trimmedTitle,
      'description': trimmedDescription,
      'dealType': normalizedType,
      'value': trimmedValue,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
      'availableDays': availableDays,
      'isActive': isActive,
      'featured': featured,
      'isDeleted': false,
      'searchTerms': ExperienceUpdatePreparation.searchTermsForValues([
        trimmedTitle,
        trimmedDescription,
        DealTypes.displayName(normalizedType),
        trimmedValue,
        venueName,
      ]),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  static Map<String, dynamic> buildUpdate({
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required bool isActive,
    required bool featured,
    required String updatedBy,
  }) {
    final normalizedType = DealTypes.normalize(dealType);
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    final trimmedValue = value.trim();

    return {
      'title': trimmedTitle,
      'description': trimmedDescription,
      'dealType': normalizedType,
      'value': trimmedValue,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
      'availableDays': availableDays,
      'isActive': isActive,
      'featured': featured,
      'searchTerms': ExperienceUpdatePreparation.searchTermsForValues([
        trimmedTitle,
        trimmedDescription,
        DealTypes.displayName(normalizedType),
        trimmedValue,
        venueName,
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  static Map<String, dynamic> buildPatch({
    required String venueName,
    required String title,
    required String description,
    required String dealType,
    required String value,
    required String updatedBy,
    String? titlePatch,
    String? dealTypePatch,
    String? valuePatch,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isActive,
    bool? featured,
  }) {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };

    final effectiveTitle = titlePatch?.trim() ?? title.trim();
    final effectiveType =
        dealTypePatch == null ? dealType : DealTypes.normalize(dealTypePatch);
    final effectiveValue = valuePatch?.trim() ?? value.trim();

    if (titlePatch != null) payload['title'] = effectiveTitle;
    if (dealTypePatch != null) payload['dealType'] = effectiveType;
    if (valuePatch != null) payload['value'] = effectiveValue;
    if (startDateTime != null) {
      payload['startDateTime'] = Timestamp.fromDate(startDateTime);
    }
    if (endDateTime != null) {
      payload['endDateTime'] = Timestamp.fromDate(endDateTime);
    }
    if (isActive != null) payload['isActive'] = isActive;
    if (featured != null) payload['featured'] = featured;

    if (titlePatch != null || dealTypePatch != null || valuePatch != null) {
      payload['searchTerms'] = ExperienceUpdatePreparation.searchTermsForValues([
        effectiveTitle,
        description,
        DealTypes.displayName(effectiveType),
        effectiveValue,
        venueName,
      ]);
    }

    return payload;
  }
}

/// Combines a calendar date with an optional HH:mm time string.
DateTime combineDealDateAndTime(DateTime date, String? time) =>
    ExperienceSchedulingUtils.combineDateAndTime(date, time);
