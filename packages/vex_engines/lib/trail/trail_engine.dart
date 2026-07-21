/// VexTrail — reusable trail lifecycle and progress engine.
///
/// See [README.md] and [MIGRATION_PLAN.md] for boundaries and migration order.
library;

export 'application/application.dart';
export 'domain/domain.dart';
export 'shared/shared.dart';

/// Marker used by package tests until runtime adapters are added.
const bool trailEngineLibraryExists = true;
