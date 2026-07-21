import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/events/vex_event.dart';
import 'package:vex_core/trails/trails.dart';
import '../domain/trail_activity_draft.dart';
import 'ports/trail_event_publisher_port.dart';
import 'trail_application_result.dart';

/// Executes repository writes and publishes events after canonical success.
final class TrailPersistenceCoordinator {
  const TrailPersistenceCoordinator({
    required this.trailRepository,
    required this.progressRepository,
    required this.activityRepository,
    required this.eventPublisher,
  });

  final TrailRepository trailRepository;
  final TrailProgressRepository progressRepository;
  final TrailActivityRepository activityRepository;
  final TrailEventPublisherPort eventPublisher;

  Future<TrailApplicationResult<void>> appendActivities(
    List<TrailActivityDraft> drafts,
  ) async {
    for (final draft in drafts) {
      final result = await activityRepository.append(
        AppendTrailActivityCommand(
          trailId: draft.trailId,
          action: draft.action,
          userId: draft.userId,
          isAnonymous: draft.isAnonymous,
          venueId: draft.venueId,
          stopOrder: draft.stopOrder,
        ),
      );
      if (result case DataFailure(error: final error)) {
        return TrailApplicationFailure(
          TrailApplicationFailureCodes.partialWriteFailure,
          'Activity append failed: ${error.message}',
          cause: error,
        );
      }
    }
    return const TrailApplicationSuccess(null);
  }

  Future<TrailApplicationResult<void>> publishEvents(
    List<VexEvent> events,
  ) async {
    if (events.isEmpty) return const TrailApplicationSuccess(null);
    try {
      await eventPublisher.publishAll(events);
      return const TrailApplicationSuccess(null);
    } on Object catch (error) {
      return TrailApplicationFailure(
        TrailApplicationFailureCodes.eventPublicationFailure,
        'Failed to publish trail events.',
        cause: error,
      );
    }
  }
}
