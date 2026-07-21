import 'package:vex_core/events/vex_event.dart';

import 'trail.dart';
import 'trail_action.dart';
import 'trail_activity_draft.dart';
import 'trail_progress.dart';
import 'trail_status.dart';

/// Planned lifecycle transition (no persistence).
final class TrailLifecycleTransitionPlan {
  const TrailLifecycleTransitionPlan({
    required this.currentStatus,
    required this.nextStatus,
    required this.action,
    required this.proposedTrail,
    required this.events,
    this.warnings = const [],
  });

  final TrailStatus currentStatus;
  final TrailStatus nextStatus;
  final TrailLifecycleAction action;
  final Trail proposedTrail;
  final List<VexEvent> events;
  final List<String> warnings;
}

/// Planned customer progress transition (no persistence).
final class TrailProgressTransitionPlan {
  const TrailProgressTransitionPlan({
    required this.action,
    required this.previousProgress,
    required this.proposedProgress,
    required this.activityDrafts,
    required this.updateActiveTrail,
    required this.activeTrailId,
    required this.mirrorLegacyProgress,
    required this.events,
    this.warnings = const [],
    this.noOp = false,
  });

  final TrailProgressAction action;
  final TrailProgress? previousProgress;
  final TrailProgress proposedProgress;
  final List<TrailActivityDraft> activityDrafts;
  final bool updateActiveTrail;
  final String activeTrailId;
  final bool mirrorLegacyProgress;
  final List<VexEvent> events;
  final List<String> warnings;
  final bool noOp;
}

/// Check-in eligibility assessment separate from progress mutation.
final class TrailCheckInAssessment {
  const TrailCheckInAssessment({
    required this.eligible,
    required this.reasonCode,
    this.reasonMessage,
    this.distanceMeters,
  });

  const TrailCheckInAssessment.allowed({this.distanceMeters})
    : eligible = true,
      reasonCode = 'allowed',
      reasonMessage = null;

  final bool eligible;
  final String reasonCode;
  final String? reasonMessage;
  final double? distanceMeters;
}

/// Completion assessment for a route/progress pair.
final class TrailCompletionAssessment {
  const TrailCompletionAssessment({
    required this.isComplete,
    required this.totalStops,
    required this.checkedInCount,
    required this.skippedCount,
    required this.unresolvedStopOrders,
    this.blockingReason,
  });

  final bool isComplete;
  final int totalStops;
  final int checkedInCount;
  final int skippedCount;
  final List<int> unresolvedStopOrders;
  final String? blockingReason;
}
