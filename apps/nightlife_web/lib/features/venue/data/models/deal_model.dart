import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_engines/experience/application/experience_deal_scheduling.dart';
import 'package:vex_engines/experience/application/experience_deal_visibility.dart';
import 'package:vex_engines/experience/application/venue_presentation_support.dart';

import '../../../venue_management/models/deal_types.dart';

const _presentation = VenuePresentationSupport();

class DealModel {
  const DealModel({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    this.dealType = DealTypes.other,
    this.value = '',
    this.startTime = '',
    this.endTime = '',
    this.startDateTime,
    this.endDateTime,
    this.availableDays = const [],
    this.isActive = true,
    this.featured = false,
    this.isDeleted = false,
    this.venueName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String venueId;
  final String title;
  final String description;
  final String dealType;
  final String value;
  final String startTime;
  final String endTime;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final List<String> availableDays;
  final bool isActive;
  final bool featured;
  final bool isDeleted;
  final String? venueName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DealModel.fromMap(String id, Map<String, dynamic> map) {
    return DealModel(
      id: id,
      venueId: map['venueId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      dealType: DealTypes.normalize(map['dealType']?.toString()),
      value: map['value']?.toString() ?? '',
      startTime: map['startTime']?.toString() ?? '',
      endTime: map['endTime']?.toString() ?? '',
      startDateTime: _dateFromValue(
        map['startDateTime'] ?? map['startsAt'] ?? map['startAt'],
      ),
      endDateTime: _dateFromValue(
        map['endDateTime'] ?? map['endsAt'] ?? map['expiresAt'] ?? map['expiryAt'],
      ),
      availableDays: _daysFromValue(map['availableDays']),
      isActive: map['isActive'] != false,
      featured: map['featured'] == true,
      isDeleted: map['isDeleted'] == true,
      venueName: map['venueName']?.toString(),
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<String> _daysFromValue(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).where((day) => day.isNotEmpty).toList();
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

  bool get isFutureDeal => ExperienceDealScheduling.isFutureStart(
        startDateTime: startDateTime,
      );

  String get displayValue => _presentation.formatDisplayValue(value);

  String get formattedStartDate => _presentation.formatDateOnly(startDateTime);

  String get formattedEndDate => _presentation.formatDateOnly(endDateTime);

  String get expiryLabel => _presentation.dealExpiryLabel(
        endDateTime: endDateTime,
        endTime: endTime,
        effectiveEndDateTime: effectiveEndDateTime,
        isFutureStart: isFutureDeal,
      );
}
