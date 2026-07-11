import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_deal_scheduling.dart';
import 'package:vex_engines/experience/application/experience_deal_visibility.dart';

class DealModel {
  final String id;
  final String venueId;
  final String title;
  final String description;
  final String startTime;
  final String endTime;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool isActive;
  final bool isDeleted;

  DealModel({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.startDateTime,
    this.endDateTime,
    this.isActive = true,
    this.isDeleted = false,
  });

  factory DealModel.fromMap(String id, Map<String, dynamic> map) {
    return DealModel(
      id: id,
      venueId: map['venueId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      startDateTime: _dateFromValue(map['startDateTime'] ?? map['startsAt'] ?? map['startAt']),
      endDateTime: _dateFromValue(map['endDateTime'] ?? map['endsAt'] ?? map['expiresAt'] ?? map['expiryAt']),
      isActive: map['isActive'] != false,
      isDeleted: map['isDeleted'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'startDateTime': startDateTime == null ? null : Timestamp.fromDate(startDateTime!),
      'endDateTime': endDateTime == null ? null : Timestamp.fromDate(endDateTime!),
      'isActive': isActive,
      'isDeleted': isDeleted,
    };
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  DateTime? get effectiveEndDateTime =>
      ExperienceDealScheduling.resolveEffectiveEndDateTime(
        endDateTime: endDateTime,
        endTime: endTime,
      );

  bool get isExpired => ExperienceDealScheduling.isExpired(
        endDateTime: endDateTime,
        endTime: endTime,
      );

  bool get isCurrentlyVisible => ExperienceDealVisibility.isPublicCurrent(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        effectiveEndDateTime: effectiveEndDateTime,
      );
}
