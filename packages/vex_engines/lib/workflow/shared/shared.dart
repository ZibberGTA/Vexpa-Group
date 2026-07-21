/// Shared workflow constants without domain business rules.
library;

export 'workflow_snapshot_mapper.dart';

/// Example workflow type ids registered by consumer engines.
abstract final class WorkflowTypeIds {
  static const venueClaim = 'venue.claim';
  static const trailVenueParticipation = 'trail.venue_participation';
}
