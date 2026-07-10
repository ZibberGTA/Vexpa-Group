/// Public visibility rules for venue events on customer surfaces.
final class ExperienceEventVisibility {
  ExperienceEventVisibility._();

  static bool isPublicCurrent({
    required bool isDeleted,
    required bool isActive,
    required DateTime startDateTime,
    required DateTime endDateTime,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (isDeleted || !isActive) return false;
    if (!endDateTime.isAfter(clock)) return false;
    if (startDateTime.isAfter(clock)) return false;

    return true;
  }

  static bool isPublicUpcoming({
    required bool isDeleted,
    required bool isActive,
    required DateTime startDateTime,
    required DateTime endDateTime,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (isDeleted || !isActive) return false;
    if (!endDateTime.isAfter(clock)) return false;

    return startDateTime.isAfter(clock);
  }

  static bool isPublicVisible({
    required bool isDeleted,
    required bool isActive,
    required DateTime startDateTime,
    required DateTime endDateTime,
    DateTime? now,
  }) =>
      isPublicCurrent(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        now: now,
      ) ||
      isPublicUpcoming(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        now: now,
      );
}
