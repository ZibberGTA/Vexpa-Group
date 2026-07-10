/// Scheduling helpers shared by deal and event management flows.
final class ExperienceSchedulingUtils {
  ExperienceSchedulingUtils._();

  /// Combines a calendar date with an optional HH:mm time string.
  static DateTime combineDateAndTime(DateTime date, String? time) {
    if (time == null || time.trim().isEmpty) {
      return DateTime(date.year, date.month, date.day);
    }

    final parts = time.trim().split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute =
          int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    return DateTime(date.year, date.month, date.day);
  }

  static DateTime mergeEventDate(DateTime existing, DateTime picked) {
    return DateTime(
      picked.year,
      picked.month,
      picked.day,
      existing.hour,
      existing.minute,
    );
  }

  static DateTime mergeEventTime(DateTime existing, String time) {
    final parts = time.trim().split(':');
    if (parts.length < 2) return existing;
    final hour = int.tryParse(parts[0]) ?? existing.hour;
    final minute =
        int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ??
            existing.minute;
    return DateTime(
      existing.year,
      existing.month,
      existing.day,
      hour,
      minute,
    );
  }
}
