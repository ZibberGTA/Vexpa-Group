import '../models/trail_model.dart';
import 'trail_service.dart';

class TrailNavGlowState {
  const TrailNavGlowState({
    required this.shouldGlow,
    this.hasActiveTrail = false,
  });

  final bool shouldGlow;
  final bool hasActiveTrail;

  static const idle = TrailNavGlowState(shouldGlow: false);
}

class TrailNavGlowService {
  TrailNavGlowService._();

  static Stream<TrailNavGlowState> watchGlowState() {
    return TrailService.watchActiveTrail().asyncExpand((trail) {
      if (trail == null || !trail.isVisible) {
        return Stream.value(TrailNavGlowState.idle);
      }

      return TrailService.watchMyTrailProgress(trailId: trail.id).map((
        progress,
      ) {
        return resolveGlowState(trail: trail, progress: progress);
      });
    });
  }

  static TrailNavGlowState resolveGlowState({
    required DrinkSpotTrailModel trail,
    TrailProgressModel? progress,
  }) {
    if (progress == null || !progress.belongsTo(trail)) {
      return TrailNavGlowState.idle;
    }

    final isActive = progress.started && !progress.completed;

    return TrailNavGlowState(
      shouldGlow: isActive,
      hasActiveTrail: isActive,
    );
  }
}
