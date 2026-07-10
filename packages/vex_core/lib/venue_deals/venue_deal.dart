/// Firebase-free public deal entity for venue promotion reads.
final class VenueDeal {
  const VenueDeal({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    required this.dealType,
    required this.value,
    required this.startTime,
    required this.endTime,
    this.startDateTime,
    this.endDateTime,
    required this.isActive,
    required this.featured,
    required this.isDeleted,
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
  final bool isActive;
  final bool featured;
  final bool isDeleted;

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
}
