/// Experience Engine — venue-published customer content (Version 1 launch engine).
///
/// Owns drinks, deals, and events plus shared publishing, visibility, scheduling,
/// validation, featured flags, and search-term preparation.
///
/// See [README.md] and [MIGRATION_PLAN.md] for boundaries and migration order.
library;

export 'application/application.dart';
export 'data/data.dart';
export 'domain/domain.dart';
export 'shared/shared.dart';

/// Marker used by package tests until runtime APIs are added.
const bool experienceEngineLibraryExists = true;
