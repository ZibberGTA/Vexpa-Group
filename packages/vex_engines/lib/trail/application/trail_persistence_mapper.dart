import 'package:vex_core/trails/trails.dart';

import '../domain/trail.dart';
import '../domain/trail_progress.dart';
import '../domain/trail_result.dart';
import '../domain/trail_status.dart';
import '../domain/trail_stop.dart';
import '../domain/trail_stop_state.dart';
import '../domain/trail_type.dart';
import '../shared/trail_snapshot_mapper.dart';

/// Maps between VexTrail domain models and VexCore persistence DTOs.
abstract final class TrailPersistenceMapper {
  static TrailSnapshot toSnapshot(Trail trail) {
    return TrailSnapshot(
      trailId: trail.id,
      name: trail.name,
      title: trail.name,
      description: trail.description,
      subtitle: trail.description,
      bannerImageUrl: trail.bannerImageUrl,
      status: KnownTrailStatusSnapshot(_statusValue(trail.status)),
      published: trail.published,
      area: trail.area,
      availabilityStart: trail.availabilityStart,
      availabilityEnd: trail.availabilityEnd,
      startTime: trail.availabilityStart,
      endTime: trail.availabilityEnd,
      estimatedDurationMinutes: trail.estimatedDurationMinutes,
      estimatedWalkingDistance: trail.estimatedWalkingDistance,
      averageRating: trail.averageRating,
      venueCount: trail.venueCount,
      trailType: KnownTrailTypeSnapshot(_typeValue(trail.trailType)),
      generatedAt: trail.generatedAt,
      stops: trail.stops.map(toStopSnapshot).toList(),
    );
  }

  static TrailStopSnapshot toStopSnapshot(TrailStop stop) {
    return TrailStopSnapshot(
      venueId: stop.venueId,
      venueName: stop.venueName,
      address: stop.address,
      bannerImageUrl: stop.bannerImageUrl,
      logoUrl: stop.logoUrl,
      order: stop.order,
      score: stop.score,
      arriveAt: stop.arriveAt,
      leaveAt: stop.leaveAt,
      discountLabel: stop.discountLabel,
    );
  }

  static TrailProgressSnapshot toProgressSnapshot(TrailProgress progress) {
    return TrailProgressSnapshot(
      trailId: progress.trailId,
      started: progress.started,
      completed: progress.completed,
      currentStop: progress.currentStopIndex,
      checkedInStops: progress.checkedInStopOrders,
      stopStates: toStopStatesSnapshot(progress.stopStates),
      trailGeneratedAt: progress.trailGeneratedAt,
      startedAt: progress.startedAt,
      updatedAt: progress.updatedAt,
      completedAt: progress.completedAt,
      lastCheckedInVenueId: progress.lastCheckedInVenueId,
      lastCheckedInStopOrder: progress.lastCheckedInStopOrder,
    );
  }

  static Map<int, TrailStopProgressStateSnapshot> toStopStatesSnapshot(
    Map<int, TrailStopState> stopStates,
  ) {
    return {
      for (final entry in stopStates.entries)
        entry.key: KnownTrailStopProgressStateSnapshot(
          _stopStateValue(entry.value),
        ),
    };
  }

  static TrailTypeValue _typeValue(TrailType type) {
    return switch (type) {
      TrailType.curated => TrailTypeValue.curated,
      TrailType.generated => TrailTypeValue.generated,
    };
  }

  static TrailStatusValue _statusValue(TrailStatus status) {
    return switch (status) {
      TrailStatus.draft => TrailStatusValue.draft,
      TrailStatus.published => TrailStatusValue.published,
      TrailStatus.disabled => TrailStatusValue.disabled,
      TrailStatus.archived => TrailStatusValue.archived,
    };
  }

  static TrailStopProgressStateValue _stopStateValue(TrailStopState state) {
    return switch (state) {
      TrailStopState.upcoming => TrailStopProgressStateValue.upcoming,
      TrailStopState.current => TrailStopProgressStateValue.current,
      TrailStopState.checkedIn => TrailStopProgressStateValue.checkedIn,
      TrailStopState.skipped => TrailStopProgressStateValue.skipped,
      TrailStopState.missed => TrailStopProgressStateValue.missed,
      TrailStopState.completed => TrailStopProgressStateValue.completed,
    };
  }

  static Trail? mapTrailOrNull(TrailSnapshot snapshot) {
    final mapped = TrailSnapshotMapper.toDomain(snapshot);
    return mapped is TrailSuccess<Trail> ? mapped.value : null;
  }

  static TrailProgress? mapProgressOrNull(TrailProgressSnapshot snapshot) {
    final mapped = TrailSnapshotMapper.progressToDomain(snapshot);
    return mapped is TrailSuccess<TrailProgress> ? mapped.value : null;
  }
}
