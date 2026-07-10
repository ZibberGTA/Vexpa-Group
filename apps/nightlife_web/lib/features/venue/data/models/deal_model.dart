import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../venue_management/models/deal_types.dart';

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

  DateTime? get effectiveEndDateTime {
    if (endDateTime != null) return endDateTime;
    final parts = endTime.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  bool get isExpired {
    final end = endDateTime ?? effectiveEndDateTime;
    return end != null && !end.isAfter(DateTime.now());
  }

  bool get isCurrentlyVisible {
    final now = DateTime.now();
    final start = startDateTime;
    final end = endDateTime ?? effectiveEndDateTime;
    return !isDeleted &&
        isActive &&
        (start == null || !start.isAfter(now)) &&
        (end == null || end.isAfter(now));
  }

  bool get isFutureDeal {
    final start = startDateTime;
    return start != null && start.isAfter(DateTime.now());
  }

  String get displayValue => value.trim().isEmpty ? '—' : value.trim();

  String get formattedStartDate => _formatDateOnly(startDateTime);

  String get formattedEndDate => _formatDateOnly(endDateTime);

  String _formatDateOnly(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String get expiryLabel {
    final end = effectiveEndDateTime ?? endDateTime;
    if (end == null) {
      if (endTime.isNotEmpty) return 'Until $endTime';
      return 'Active now';
    }
    if (isFutureDeal) return 'Starts ${_formatDateTime(end)}';
    return 'Ends ${_formatDateTime(end)}';
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
