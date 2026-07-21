import 'package:vex_core/events/vex_event.dart';

/// Trail lifecycle domain events (consumer-neutral).
final class TrailPublishedEvent extends VexEvent {
  TrailPublishedEvent({
    required super.id,
    required super.occurredAt,
    required this.trailId,
  });

  final String trailId;

  @override
  String get type => 'trail.published';
}

final class TrailUnpublishedEvent extends VexEvent {
  TrailUnpublishedEvent({
    required super.id,
    required super.occurredAt,
    required this.trailId,
  });

  final String trailId;

  @override
  String get type => 'trail.unpublished';
}

final class TrailArchivedEvent extends VexEvent {
  TrailArchivedEvent({
    required super.id,
    required super.occurredAt,
    required this.trailId,
  });

  final String trailId;

  @override
  String get type => 'trail.archived';
}

final class TrailJoinedEvent extends VexEvent {
  TrailJoinedEvent({
    required super.id,
    required super.occurredAt,
    required this.trailId,
    required this.userId,
  });

  final String trailId;
  final String userId;

  @override
  String get type => 'trail.joined';
}

final class TrailStopCheckedInEvent extends VexEvent {
  TrailStopCheckedInEvent({
    required super.id,
    required super.occurredAt,
    required this.trailId,
    required this.userId,
    required this.stopOrder,
    required this.venueId,
  });

  final String trailId;
  final String userId;
  final int stopOrder;
  final String venueId;

  @override
  String get type => 'trail.stop_checked_in';
}

final class TrailStopSkippedEvent extends VexEvent {
  TrailStopSkippedEvent({
    required super.id,
    required super.occurredAt,
    required this.trailId,
    required this.userId,
    required this.stopOrder,
  });

  final String trailId;
  final String userId;
  final int stopOrder;

  @override
  String get type => 'trail.stop_skipped';
}

final class TrailAdvancedEvent extends VexEvent {
  TrailAdvancedEvent({
    required super.id,
    required super.occurredAt,
    required this.trailId,
    required this.userId,
    required this.fromStopIndex,
    required this.toStopIndex,
  });

  final String trailId;
  final String userId;
  final int fromStopIndex;
  final int? toStopIndex;

  @override
  String get type => 'trail.advanced';
}

final class TrailCompletedEvent extends VexEvent {
  TrailCompletedEvent({
    required super.id,
    required super.occurredAt,
    required this.trailId,
    required this.userId,
  });

  final String trailId;
  final String userId;

  @override
  String get type => 'trail.completed';
}
