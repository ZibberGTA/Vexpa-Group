/// Deal timing helpers shared by visibility, status, and lifecycle flows.
final class ExperienceDealScheduling {
  ExperienceDealScheduling._();

  /// Resolves the effective end instant from an explicit end date or HH:mm time.
  static DateTime? resolveEffectiveEndDateTime({
    DateTime? endDateTime,
    required String endTime,
    DateTime? now,
  }) {
    if (endDateTime != null) return endDateTime;

    final parts = endTime.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
    if (hour == null || minute == null) return null;

    final clock = now ?? DateTime.now();
    return DateTime(clock.year, clock.month, clock.day, hour, minute);
  }

  static bool isExpired({
    DateTime? endDateTime,
    required String endTime,
    DateTime? now,
  }) {
    final end = resolveEffectiveEndDateTime(
      endDateTime: endDateTime,
      endTime: endTime,
      now: now,
    );
    final clock = now ?? DateTime.now();
    return end != null && !end.isAfter(clock);
  }

  static bool isFutureStart({
    DateTime? startDateTime,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    return startDateTime != null && startDateTime.isAfter(clock);
  }
}
