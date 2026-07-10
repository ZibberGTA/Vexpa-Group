import '../domain/venue_opening_hours_entry.dart';

/// Formats venue opening hours maps for presentation.
final class VenueOpeningHoursFormatter {
  VenueOpeningHoursFormatter._();

  static const _dayKeys = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const _dayLabels = <String, String>{
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  static List<VenueOpeningHoursEntry> fromMap(
    Map<String, dynamic> hours, {
    DateTime? now,
  }) {
    if (hours.isEmpty) return const [];

    final clock = now ?? DateTime.now();
    final todayKey = _dayKeys[clock.weekday - 1];

    return _dayKeys.map((key) {
      final raw = hours[key];
      final dayData = raw is Map ? Map<String, dynamic>.from(raw) : null;
      final closed =
          dayData == null ||
          dayData['closed'] == true ||
          dayData['isClosed'] == true;

      if (closed) {
        return VenueOpeningHoursEntry(
          dayLabel: _dayLabels[key] ?? key,
          hoursLabel: 'Closed',
          isToday: key == todayKey,
          isClosed: true,
        );
      }

      final open = _formatTime(dayData['open']);
      final close = _formatTime(dayData['close']);

      return VenueOpeningHoursEntry(
        dayLabel: _dayLabels[key] ?? key,
        hoursLabel: open != null && close != null
            ? '$open – $close'
            : 'Hours unavailable',
        isToday: key == todayKey,
      );
    }).toList();
  }

  static String? _formatTime(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length < 2) return text;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return text;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
