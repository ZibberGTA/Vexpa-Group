/// VexWorkflow — reusable approval and request lifecycle engine.
///
/// See [README.md] and [MIGRATION_PLAN.md] for boundaries and migration order.
library;

export 'application/application.dart';
export 'data/data.dart';
export 'domain/domain.dart';
export 'shared/shared.dart';

/// Marker used by package tests until runtime adapters are added.
const bool workflowEngineLibraryExists = true;
