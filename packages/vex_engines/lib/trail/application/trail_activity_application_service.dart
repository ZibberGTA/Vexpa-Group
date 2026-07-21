import '../domain/trail_activity_draft.dart';
import 'ports/trail_user_context_port.dart';
import 'trail_activity_composer.dart';
import 'trail_application_result.dart';
import 'trail_persistence_coordinator.dart';

/// Append-only trail activity orchestration (directions, diagnostics).
final class TrailActivityApplicationService {
  const TrailActivityApplicationService({
    required this.coordinator,
    required this.userContext,
  });

  final TrailPersistenceCoordinator coordinator;
  final TrailUserContextPort userContext;

  Future<TrailApplicationResult<void>> logDirectionsRequested({
    required String trailId,
    required String venueId,
    required int stopOrder,
  }) async {
    return _append(
      TrailActivityComposer.directionsRequested(
        trailId: trailId,
        venueId: venueId,
        stopOrder: stopOrder,
      ),
    );
  }

  Future<TrailApplicationResult<void>> logAction({
    required String trailId,
    required String action,
    String? venueId,
    int? stopOrder,
  }) async {
    return _append(
      TrailActivityDraft(
        trailId: trailId,
        action: action,
        venueId: venueId,
        stopOrder: stopOrder,
      ),
    );
  }

  Future<TrailApplicationResult<void>> _append(TrailActivityDraft draft) async {
    final user = userContext.currentUser();
    final enriched = TrailActivityDraft(
      trailId: draft.trailId,
      action: draft.action,
      userId: user.userId,
      isAnonymous: user.isAnonymous,
      venueId: draft.venueId,
      stopOrder: draft.stopOrder,
    );
    return coordinator.appendActivities([enriched]);
  }
}
