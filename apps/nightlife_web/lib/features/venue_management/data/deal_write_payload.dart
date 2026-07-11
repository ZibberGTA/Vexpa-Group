import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_scheduling_utils.dart';
import 'package:vex_engines/experience/application/experience_write_preparation.dart';

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
    final fields = ExperienceWritePreparation.dealCreateFields(
      venueId: venueId,
      venueName: venueName,
      title: title,
      description: description,
      dealType: dealType,
      value: value,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      availableDays: availableDays,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
      featured: featured,
      createdBy: createdBy,
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
    final fields = ExperienceWritePreparation.dealUpdateFields(
      venueName: venueName,
      title: title,
      description: description,
      dealType: dealType,
      value: value,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      availableDays: availableDays,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
      featured: featured,
      updatedBy: updatedBy,
    );

    return {
      ...fields,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'updatedAt': FieldValue.serverTimestamp(),
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
    final fields = ExperienceWritePreparation.dealPatchFields(
      venueName: venueName,
      title: title,
      description: description,
      dealType: dealType,
      value: value,
      updatedBy: updatedBy,
      titlePatch: titlePatch,
      dealTypePatch: dealTypePatch,
      valuePatch: valuePatch,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isActive: isActive,
      featured: featured,
    );

    if (startDateTime != null) {
      fields['startDateTime'] = Timestamp.fromDate(startDateTime);
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

/// Combines a calendar date with an optional HH:mm time string.
DateTime combineDealDateAndTime(DateTime date, String? time) =>
    ExperienceSchedulingUtils.combineDateAndTime(date, time);
