import 'package:vex_engines/experience/application/experience_deal_status.dart';

import '../../venue/data/models/deal_model.dart';

typedef DealStatus = ExperienceDealManagementStatus;

extension DealStatusX on DealStatus {
  String get label => switch (this) {
        DealStatus.active => 'Active',
        DealStatus.scheduled => 'Scheduled',
        DealStatus.expired => 'Expired',
        DealStatus.paused => 'Paused',
      };
}

/// Derives management status for a deal row badge.
DealStatus computeDealStatus(DealModel deal, {DateTime? now}) =>
    ExperienceDealStatusRules.compute(
      isActive: deal.isActive,
      startDateTime: deal.startDateTime,
      endDateTime: deal.endDateTime,
      effectiveEndDateTime: deal.effectiveEndDateTime,
      now: now,
    );

/// Returns true when deal passes status filter set (includes Featured pseudo-filter).
bool dealPassesStatusFilters(DealModel deal, Set<String> selectedFilters) =>
    ExperienceDealStatusRules.passesStatusFilters(
      status: computeDealStatus(deal),
      featured: deal.featured,
      selectedFilters: selectedFilters,
    );

const dealStatusFilterOptions = experienceDealStatusFilterOptions;
