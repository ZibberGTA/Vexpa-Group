/// Growth Engine — commercial decisions, boosts, upgrades, and recommendations.
///
/// See [README.md] and [MIGRATION_PLAN.md] for boundaries and migration order.
library;

export 'application/application.dart';
export 'data/data.dart';
export 'domain/domain.dart';
export 'shared/shared.dart';

/// Marker used by package tests until all runtime APIs are wired.
const bool growthEngineLibraryExists = true;
