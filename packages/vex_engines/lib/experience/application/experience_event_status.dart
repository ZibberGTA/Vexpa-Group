/// Management lifecycle status for venue events in owner dashboards.
enum ExperienceEventManagementStatus {
  draft,
  upcoming,
  live,
  ended,
}

extension ExperienceEventManagementStatusX on ExperienceEventManagementStatus {
  String get label => switch (this) {
        ExperienceEventManagementStatus.draft => 'Draft',
        ExperienceEventManagementStatus.upcoming => 'Upcoming',
        ExperienceEventManagementStatus.live => 'Live',
        ExperienceEventManagementStatus.ended => 'Ended',
      };
}

/// Derives management status for event rows and filters.
final class ExperienceEventStatusRules {
  ExperienceEventStatusRules._();

  static ExperienceEventManagementStatus compute({
    required bool isActive,
    required DateTime startDateTime,
    required DateTime endDateTime,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();

    if (!isActive) return ExperienceEventManagementStatus.draft;
    if (!endDateTime.isAfter(clock)) {
      return ExperienceEventManagementStatus.ended;
    }
    if (startDateTime.isAfter(clock)) {
      return ExperienceEventManagementStatus.upcoming;
    }

    return ExperienceEventManagementStatus.live;
  }
}
