import '../../venue/data/models/deal_model.dart';

enum DealStatus {
  active,
  scheduled,
  expired,
  paused,
}

extension DealStatusX on DealStatus {
  String get label => switch (this) {
        DealStatus.active => 'Active',
        DealStatus.scheduled => 'Scheduled',
        DealStatus.expired => 'Expired',
        DealStatus.paused => 'Paused',
      };
}

/// Derives management status for a deal row badge.
DealStatus computeDealStatus(DealModel deal, {DateTime? now}) {
  final clock = now ?? DateTime.now();

  if (!deal.isActive) return DealStatus.paused;

  final start = deal.startDateTime;
  final end = deal.endDateTime ?? deal.effectiveEndDateTime;

  if (end != null && !end.isAfter(clock)) return DealStatus.expired;
  if (start != null && start.isAfter(clock)) return DealStatus.scheduled;

  return DealStatus.active;
}

/// Returns true when deal passes status filter set (includes Featured pseudo-filter).
bool dealPassesStatusFilters(DealModel deal, Set<String> selectedFilters) {
  if (selectedFilters.isEmpty) return true;

  final statusFilters = <DealStatus>{};
  var wantsFeatured = false;

  for (final filter in selectedFilters) {
    if (filter == 'Featured') {
      wantsFeatured = true;
      continue;
    }
    final status = DealStatus.values.firstWhere(
      (value) => value.label == filter,
      orElse: () => DealStatus.active,
    );
    statusFilters.add(status);
  }

  final statusMatch = statusFilters.isEmpty ||
      statusFilters.contains(computeDealStatus(deal));
  final featuredMatch = !wantsFeatured || deal.featured;

  if (statusFilters.isNotEmpty && wantsFeatured) {
    return statusMatch && featuredMatch;
  }
  if (wantsFeatured) return featuredMatch;
  return statusMatch;
}

const dealStatusFilterOptions = [
  'Active',
  'Scheduled',
  'Expired',
  'Paused',
  'Featured',
];
