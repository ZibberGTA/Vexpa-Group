import 'trail.dart';
import 'trail_action.dart';
import 'trail_result.dart';
import 'trail_status.dart';

/// Allowed lifecycle transitions in the current product.
abstract final class TrailLifecyclePolicy {
  static TrailResult<TrailLifecycleAction> validateTransition({
    required Trail trail,
    required TrailLifecycleAction action,
  }) {
    return switch (action) {
      TrailLifecycleAction.createDraft => const TrailSuccess(
        TrailLifecycleAction.createDraft,
      ),
      TrailLifecycleAction.updateDraft => _allowDraftLike(trail, action),
      TrailLifecycleAction.saveStops => _allowDraftLike(trail, action),
      TrailLifecycleAction.publish => _allowPublish(trail),
      TrailLifecycleAction.unpublish => _allowFromPublished(trail, action),
      TrailLifecycleAction.archive || TrailLifecycleAction.disable =>
        const TrailSuccess(TrailLifecycleAction.archive),
      TrailLifecycleAction.duplicate => const TrailSuccess(
        TrailLifecycleAction.duplicate,
      ),
      TrailLifecycleAction.delete => const TrailSuccess(
        TrailLifecycleAction.delete,
      ),
      TrailLifecycleAction.replaceDocument => _allowDraftLike(trail, action),
    };
  }

  static Trail applyTransition({
    required Trail trail,
    required TrailLifecycleAction action,
  }) {
    return switch (action) {
      TrailLifecycleAction.publish => trail.copyWith(
        status: TrailStatus.published,
        published: true,
      ),
      TrailLifecycleAction.unpublish => trail.copyWith(
        status: TrailStatus.draft,
        published: false,
      ),
      TrailLifecycleAction.archive || TrailLifecycleAction.disable =>
        trail.copyWith(status: TrailStatus.archived, published: false),
      TrailLifecycleAction.saveStops => trail.copyWith(
        status: TrailStatus.draft,
        published: false,
      ),
      TrailLifecycleAction.duplicate => trail.copyWith(
        name: '${trail.name} Copy',
        status: TrailStatus.draft,
        published: false,
        generatedAt: trail.generatedAt,
      ),
      _ => trail,
    };
  }

  static TrailResult<TrailLifecycleAction> _allowDraftLike(
    Trail trail,
    TrailLifecycleAction action,
  ) {
    if (trail.status == TrailStatus.archived) {
      return const TrailFailure(
        TrailFailureCodes.invalidTransition,
        'Archived trails cannot be edited.',
      );
    }
    return TrailSuccess(action);
  }

  static TrailResult<TrailLifecycleAction> _allowPublish(Trail trail) {
    if (trail.status == TrailStatus.archived ||
        trail.status == TrailStatus.disabled) {
      return const TrailFailure(
        TrailFailureCodes.invalidTransition,
        'Archived or disabled trails cannot be published.',
      );
    }
    return const TrailSuccess(TrailLifecycleAction.publish);
  }

  static TrailResult<TrailLifecycleAction> _allowFromPublished(
    Trail trail,
    TrailLifecycleAction action,
  ) {
    if (trail.status == TrailStatus.archived) {
      return const TrailFailure(
        TrailFailureCodes.invalidTransition,
        'Archived trails cannot be unpublished.',
      );
    }
    return TrailSuccess(action);
  }
}
