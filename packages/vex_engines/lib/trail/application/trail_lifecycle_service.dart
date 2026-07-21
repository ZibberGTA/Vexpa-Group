import 'package:vex_core/events/vex_event.dart';

import '../domain/trail.dart';
import '../domain/trail_action.dart';
import '../domain/trail_events.dart';
import '../domain/trail_lifecycle_policy.dart';
import '../domain/trail_publication_policy.dart';
import '../domain/trail_result.dart';
import '../domain/trail_transition_plan.dart';

/// Pure lifecycle transition planning.
final class TrailLifecycleService {
  const TrailLifecycleService();

  TrailResult<TrailLifecycleTransitionPlan> plan({
    required Trail trail,
    required TrailLifecycleAction action,
    required DateTime occurredAt,
    required String eventId,
    bool requirePublicationReadiness = false,
  }) {
    final validation = TrailLifecyclePolicy.validateTransition(
      trail: trail,
      action: action,
    );
    if (validation case TrailFailure()) {
      return TrailFailure(validation.code, validation.message);
    }

    if (action == TrailLifecycleAction.publish && requirePublicationReadiness) {
      if (!TrailPublicationPolicy.isReady(trail)) {
        return const TrailFailure(
          TrailFailureCodes.publicationNotReady,
          'Trail is not ready to publish.',
        );
      }
    }

    final proposed = TrailLifecyclePolicy.applyTransition(
      trail: trail,
      action: action,
    );

    final events = <VexEvent>[];
    switch (action) {
      case TrailLifecycleAction.publish:
        events.add(
          TrailPublishedEvent(
            id: eventId,
            occurredAt: occurredAt,
            trailId: trail.id,
          ),
        );
      case TrailLifecycleAction.unpublish:
        events.add(
          TrailUnpublishedEvent(
            id: eventId,
            occurredAt: occurredAt,
            trailId: trail.id,
          ),
        );
      case TrailLifecycleAction.archive:
      case TrailLifecycleAction.disable:
        events.add(
          TrailArchivedEvent(
            id: eventId,
            occurredAt: occurredAt,
            trailId: trail.id,
          ),
        );
      default:
        break;
    }

    return TrailSuccess(
      TrailLifecycleTransitionPlan(
        currentStatus: trail.status,
        nextStatus: proposed.status,
        action: action,
        proposedTrail: proposed,
        events: events,
      ),
    );
  }
}
