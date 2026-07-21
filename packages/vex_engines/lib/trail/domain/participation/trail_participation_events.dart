import 'package:vex_core/events/vex_event.dart';

/// Trail-specific participation events emitted alongside generic workflow events.
sealed class TrailParticipationEvent extends VexEvent {
  const TrailParticipationEvent({
    required super.id,
    required super.occurredAt,
    required this.requestId,
    required this.trailId,
    required this.venueId,
  });

  final String requestId;
  final String trailId;
  final String venueId;
}

final class TrailParticipationSubmittedEvent extends TrailParticipationEvent {
  const TrailParticipationSubmittedEvent({
    required super.id,
    required super.requestId,
    required super.trailId,
    required super.venueId,
    required super.occurredAt,
  });

  @override
  String get type => 'trail.participation.submitted';
}

final class TrailParticipationResubmittedEvent extends TrailParticipationEvent {
  const TrailParticipationResubmittedEvent({
    required super.id,
    required super.requestId,
    required super.trailId,
    required super.venueId,
    required super.occurredAt,
  });

  @override
  String get type => 'trail.participation.resubmitted';
}

final class TrailParticipationWithdrawnEvent extends TrailParticipationEvent {
  const TrailParticipationWithdrawnEvent({
    required super.id,
    required super.requestId,
    required super.trailId,
    required super.venueId,
    required super.occurredAt,
  });

  @override
  String get type => 'trail.participation.withdrawn';
}

final class TrailParticipationApprovedEvent extends TrailParticipationEvent {
  const TrailParticipationApprovedEvent({
    required super.id,
    required super.requestId,
    required super.trailId,
    required super.venueId,
    required super.occurredAt,
    this.approvalPlan,
  });

  final Object? approvalPlan;

  @override
  String get type => 'trail.participation.approved';
}

final class TrailParticipationRejectedEvent extends TrailParticipationEvent {
  const TrailParticipationRejectedEvent({
    required super.id,
    required super.requestId,
    required super.trailId,
    required super.venueId,
    required super.occurredAt,
    this.reason,
  });

  final String? reason;

  @override
  String get type => 'trail.participation.rejected';
}
