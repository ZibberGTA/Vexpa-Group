import '../trail.dart';
import '../trail_status.dart';
import '../trail_type.dart';
import 'trail_participation_blocking_reason.dart';
import 'trail_participation_duplicate_policy.dart';
import 'trail_participation_settings.dart';
import '../../../workflow/domain/workflow_status.dart';

/// Inputs supplied to the pure participation eligibility policy.
final class TrailParticipationEligibilityInput {
  const TrailParticipationEligibilityInput({
    required this.trail,
    required this.venueId,
    required this.requestedStopOrder,
    required this.venueIsManageable,
    required this.existingApplicationStatuses,
    this.now,
  });

  final Trail trail;
  final String venueId;
  final int requestedStopOrder;
  final bool venueIsManageable;
  final List<WorkflowStatus> existingApplicationStatuses;
  final DateTime? now;
}

/// Result of participation eligibility evaluation.
final class TrailParticipationEligibilityResult {
  const TrailParticipationEligibilityResult({
    required this.eligible,
    this.blockingReasons = const [],
    this.warnings = const [],
    this.validRequestedPositions = const [],
    this.suggestedPosition,
  });

  final bool eligible;
  final List<String> blockingReasons;
  final List<String> warnings;
  final List<int> validRequestedPositions;
  final int? suggestedPosition;
}

/// Pure policy determining whether a venue may apply to participate in a trail.
abstract final class TrailParticipationEligibilityPolicy {
  static TrailParticipationEligibilityResult evaluate(
    TrailParticipationEligibilityInput input,
  ) {
    final blocking = <String>[];
    final warnings = <String>[];
    final trail = input.trail;
    final settings = trail.participationSettings;
    final now = input.now ?? DateTime.now();

    if (!input.venueIsManageable) {
      blocking.add(TrailParticipationBlockingReason.venueNotManageable);
    }

    if (trail.status == TrailStatus.archived ||
        trail.status == TrailStatus.disabled) {
      blocking.add(TrailParticipationBlockingReason.trailArchivedOrDisabled);
    }

    if (!trail.isPublishedLike) {
      blocking.add(TrailParticipationBlockingReason.trailNotPublished);
    }

    if (trail.trailType != TrailType.curated) {
      blocking.add(TrailParticipationBlockingReason.trailTypeNotSupported);
    }

    if (!settings.acceptsVenueApplications) {
      blocking.add(TrailParticipationBlockingReason.applicationsNotAccepted);
    }

    final opensAt = settings.participationApplicationOpensAt;
    if (opensAt != null && now.isBefore(opensAt)) {
      blocking.add(TrailParticipationBlockingReason.applicationWindowNotOpen);
    }

    final closesAt = settings.participationApplicationClosesAt;
    if (closesAt != null && !now.isBefore(closesAt)) {
      blocking.add(TrailParticipationBlockingReason.applicationWindowClosed);
    }

    if (trail.stops.any((stop) => stop.venueId == input.venueId)) {
      blocking.add(TrailParticipationBlockingReason.venueAlreadyStop);
    }

    for (final status in input.existingApplicationStatuses) {
      if (status == WorkflowStatus.approved) {
        blocking.add(
          TrailParticipationBlockingReason.approvedApplicationExists,
        );
        break;
      }
      if (TrailParticipationDuplicatePolicy.blockingOpenStatuses.contains(
        status,
      )) {
        blocking.add(TrailParticipationBlockingReason.duplicateOpenApplication);
        break;
      }
    }

    final stopCount = trail.stops.length;
    final maximumStops = settings.maximumStops;
    if (maximumStops != null && stopCount >= maximumStops) {
      blocking.add(TrailParticipationBlockingReason.trailCapacityReached);
    }

    final validPositions = _validRequestedPositions(
      trail: trail,
      settings: settings,
      stopCount: stopCount,
      maximumStops: maximumStops,
    );

    if (input.requestedStopOrder > 0 &&
        !validPositions.contains(input.requestedStopOrder)) {
      blocking.add(TrailParticipationBlockingReason.invalidRequestedPosition);
    }

    final suggested = validPositions.isEmpty ? null : validPositions.last;

    return TrailParticipationEligibilityResult(
      eligible: blocking.isEmpty,
      blockingReasons: blocking,
      warnings: warnings,
      validRequestedPositions: validPositions,
      suggestedPosition: suggested,
    );
  }

  static List<int> _validRequestedPositions({
    required Trail trail,
    required TrailParticipationSettings settings,
    required int stopCount,
    required int? maximumStops,
  }) {
    if (maximumStops != null && stopCount >= maximumStops) {
      return const [];
    }

    final appendPosition = stopCount + 1;
    if (!settings.venueSelectableStopPosition) {
      return [appendPosition];
    }

    final positions = <int>[for (var i = 1; i <= appendPosition; i++) i];
    return positions;
  }
}
