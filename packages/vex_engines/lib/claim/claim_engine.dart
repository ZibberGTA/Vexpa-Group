/// Claim Engine — venue claim submission, review, and ownership verification.
///
/// See [README.md] and [MIGRATION_PLAN.md] for boundaries and migration order.
library;

export 'application/application.dart';
export 'data/data.dart';
export 'domain/domain.dart';
export 'shared/shared.dart';

/// Marker used by package tests until runtime APIs are added.
const bool claimEngineLibraryExists = true;
