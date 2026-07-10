/// Public visibility rules for venue deals on customer surfaces.
final class ExperienceDealVisibility {
  ExperienceDealVisibility._();

  static bool isPublicCurrent({
    required bool isDeleted,
    required bool isActive,
    DateTime? startDateTime,
    DateTime? endDateTime,
    DateTime? effectiveEndDateTime,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (isDeleted || !isActive) return false;

    final end = endDateTime ?? effectiveEndDateTime;
    if (end != null && !end.isAfter(clock)) return false;
    if (startDateTime != null && startDateTime.isAfter(clock)) return false;

    return true;
  }

  static bool isPublicUpcoming({
    required bool isDeleted,
    required bool isActive,
    DateTime? startDateTime,
    DateTime? endDateTime,
    DateTime? effectiveEndDateTime,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (isDeleted || !isActive) return false;

    if (startDateTime == null || !startDateTime.isAfter(clock)) return false;

    final end = endDateTime ?? effectiveEndDateTime;
    if (end != null && !end.isAfter(clock)) return false;

    return true;
  }

  static bool isPublicVisible({
    required bool isDeleted,
    required bool isActive,
    DateTime? startDateTime,
    DateTime? endDateTime,
    DateTime? effectiveEndDateTime,
    DateTime? now,
  }) =>
      isPublicCurrent(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        effectiveEndDateTime: effectiveEndDateTime,
        now: now,
      ) ||
      isPublicUpcoming(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        effectiveEndDateTime: effectiveEndDateTime,
        now: now,
      );
}
