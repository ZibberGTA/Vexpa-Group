/// Management lifecycle status for venue deals in owner dashboards.
enum ExperienceDealManagementStatus {
  active,
  scheduled,
  expired,
  paused,
}

extension ExperienceDealManagementStatusX on ExperienceDealManagementStatus {
  String get label => switch (this) {
        ExperienceDealManagementStatus.active => 'Active',
        ExperienceDealManagementStatus.scheduled => 'Scheduled',
        ExperienceDealManagementStatus.expired => 'Expired',
        ExperienceDealManagementStatus.paused => 'Paused',
      };
}

/// Derives management status and filter matching for deal tables.
final class ExperienceDealStatusRules {
  ExperienceDealStatusRules._();

  static ExperienceDealManagementStatus compute({
    required bool isActive,
    DateTime? startDateTime,
    DateTime? endDateTime,
    DateTime? effectiveEndDateTime,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();

    if (!isActive) return ExperienceDealManagementStatus.paused;

    final end = endDateTime ?? effectiveEndDateTime;
    if (end != null && !end.isAfter(clock)) {
      return ExperienceDealManagementStatus.expired;
    }
    if (startDateTime != null && startDateTime.isAfter(clock)) {
      return ExperienceDealManagementStatus.scheduled;
    }

    return ExperienceDealManagementStatus.active;
  }

  /// Returns true when deal passes status filter set (includes Featured pseudo-filter).
  static bool passesStatusFilters({
    required ExperienceDealManagementStatus status,
    required bool featured,
    required Set<String> selectedFilters,
  }) {
    if (selectedFilters.isEmpty) return true;

    final statusFilters = <ExperienceDealManagementStatus>{};
    var wantsFeatured = false;

    for (final filter in selectedFilters) {
      if (filter == 'Featured') {
        wantsFeatured = true;
        continue;
      }
      final match = ExperienceDealManagementStatus.values.firstWhere(
        (value) => value.label == filter,
        orElse: () => ExperienceDealManagementStatus.active,
      );
      statusFilters.add(match);
    }

    final statusMatch =
        statusFilters.isEmpty || statusFilters.contains(status);
    final featuredMatch = !wantsFeatured || featured;

    if (statusFilters.isNotEmpty && wantsFeatured) {
      return statusMatch && featuredMatch;
    }
    if (wantsFeatured) return featuredMatch;
    return statusMatch;
  }
}

const experienceDealStatusFilterOptions = [
  'Active',
  'Scheduled',
  'Expired',
  'Paused',
  'Featured',
];
