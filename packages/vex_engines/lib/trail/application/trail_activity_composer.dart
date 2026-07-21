import '../domain/trail_activity_draft.dart';
import '../domain/trail_action.dart';

/// Creates activity drafts with consistent persisted action strings.
abstract final class TrailActivityComposer {
  static TrailActivityDraft started({
    required String trailId,
    String? userId,
    bool isAnonymous = false,
  }) {
    return TrailActivityDraft(
      trailId: trailId,
      action: TrailActivityType.started,
      userId: userId,
      isAnonymous: isAnonymous,
    );
  }

  static TrailActivityDraft arrived({
    required String trailId,
    required String venueId,
    required int stopOrder,
    String? userId,
    bool isAnonymous = false,
  }) {
    return TrailActivityDraft(
      trailId: trailId,
      action: TrailActivityType.arrived,
      userId: userId,
      isAnonymous: isAnonymous,
      venueId: venueId,
      stopOrder: stopOrder,
    );
  }

  static TrailActivityDraft forContinue({
    required String trailId,
    required String venueId,
    required int stopOrder,
    required bool completed,
    String? userId,
    bool isAnonymous = false,
  }) {
    return TrailActivityDraft(
      trailId: trailId,
      action: completed
          ? TrailActivityType.completed
          : TrailActivityType.continueNext,
      userId: userId,
      isAnonymous: isAnonymous,
      venueId: venueId,
      stopOrder: stopOrder,
    );
  }

  static TrailActivityDraft forSkip({
    required String trailId,
    required String venueId,
    required int stopOrder,
    required bool completed,
    String? userId,
    bool isAnonymous = false,
  }) {
    return TrailActivityDraft(
      trailId: trailId,
      action: completed
          ? TrailActivityType.completedAfterSkip
          : TrailActivityType.skippedStop,
      userId: userId,
      isAnonymous: isAnonymous,
      venueId: venueId,
      stopOrder: stopOrder,
    );
  }

  static TrailActivityDraft directionsRequested({
    required String trailId,
    required String venueId,
    required int stopOrder,
    String? userId,
    bool isAnonymous = false,
  }) {
    return TrailActivityDraft(
      trailId: trailId,
      action: TrailActivityType.directionsRequested,
      userId: userId,
      isAnonymous: isAnonymous,
      venueId: venueId,
      stopOrder: stopOrder,
    );
  }

  static TrailActivityDraft forProgressAction({
    required TrailProgressAction action,
    required String trailId,
    required String venueId,
    required int stopOrder,
    required bool completed,
    String? userId,
    bool isAnonymous = false,
  }) {
    return switch (action) {
      TrailProgressAction.join || TrailProgressAction.resume => started(
        trailId: trailId,
        userId: userId,
        isAnonymous: isAnonymous,
      ),
      TrailProgressAction.checkIn => arrived(
        trailId: trailId,
        venueId: venueId,
        stopOrder: stopOrder,
        userId: userId,
        isAnonymous: isAnonymous,
      ),
      TrailProgressAction.continueStop => forContinue(
        trailId: trailId,
        venueId: venueId,
        stopOrder: stopOrder,
        completed: completed,
        userId: userId,
        isAnonymous: isAnonymous,
      ),
      TrailProgressAction.skipStop => forSkip(
        trailId: trailId,
        venueId: venueId,
        stopOrder: stopOrder,
        completed: completed,
        userId: userId,
        isAnonymous: isAnonymous,
      ),
    };
  }
}
