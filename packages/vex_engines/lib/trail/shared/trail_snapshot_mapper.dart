import 'package:vex_core/trails/trail_snapshots.dart';

import '../domain/participation/trail_participation_settings.dart';
import '../domain/trail.dart';
import '../domain/trail_progress.dart';
import '../domain/trail_result.dart';
import '../domain/trail_status.dart';
import '../domain/trail_stop.dart';
import '../domain/trail_stop_state.dart';
import '../domain/trail_type.dart';

/// Maps VexCore snapshots into normalized VexTrail domain models.
abstract final class TrailSnapshotMapper {
  static TrailResult<Trail> toDomain(TrailSnapshot snapshot) {
    final status = _mapStatus(snapshot.status);
    if (status case TrailFailure()) {
      return TrailFailure(status.code, status.message);
    }
    final trailType = _mapType(snapshot.trailType);
    if (trailType case TrailFailure()) {
      return TrailFailure(trailType.code, trailType.message);
    }

    final stops = [
      for (final stop in snapshot.stops)
        TrailStop(
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
        ),
    ]..sort((a, b) => a.order.compareTo(b.order));

    return TrailSuccess(
      Trail(
        id: snapshot.trailId,
        name: _resolveName(snapshot),
        description: _resolveDescription(snapshot),
        bannerImageUrl: snapshot.bannerImageUrl,
        status: (status as TrailSuccess<TrailStatus>).value,
        published: snapshot.published,
        area: snapshot.area,
        availabilityStart: snapshot.availabilityStart,
        availabilityEnd: snapshot.availabilityEnd,
        estimatedDurationMinutes: snapshot.estimatedDurationMinutes,
        estimatedWalkingDistance: snapshot.estimatedWalkingDistance,
        averageRating: snapshot.averageRating,
        venueCount: snapshot.venueCount,
        trailType: (trailType as TrailSuccess<TrailType>).value,
        generatedAt: snapshot.generatedAt,
        stops: stops,
        participationSettings: TrailParticipationSettings(
          acceptsVenueApplications:
              snapshot.participationSettings.acceptsVenueApplications,
          participationApplicationOpensAt:
              snapshot.participationSettings.participationApplicationOpensAt,
          participationApplicationClosesAt:
              snapshot.participationSettings.participationApplicationClosesAt,
          maximumStops: snapshot.participationSettings.maximumStops,
          venueSelectableStopPosition:
              snapshot.participationSettings.venueSelectableStopPosition,
          participationInstructions:
              snapshot.participationSettings.participationInstructions,
        ),
      ),
    );
  }

  static TrailResult<TrailProgress> progressToDomain(
    TrailProgressSnapshot snapshot,
  ) {
    final stopStates = <int, TrailStopState>{};
    for (final entry in snapshot.stopStates.entries) {
      final mapped = _mapStopState(entry.value);
      if (mapped case TrailFailure()) {
        return TrailFailure(mapped.code, mapped.message);
      }
      stopStates[entry.key] = (mapped as TrailSuccess<TrailStopState>).value;
    }

    for (final order in snapshot.checkedInStops) {
      stopStates.putIfAbsent(order, () => TrailStopState.checkedIn);
    }

    return TrailSuccess(
      TrailProgress(
        trailId: snapshot.trailId,
        started: snapshot.started,
        completed: snapshot.completed,
        currentStopIndex: snapshot.currentStop,
        checkedInStopOrders: Set<int>.from(snapshot.checkedInStops),
        stopStates: stopStates,
        trailGeneratedAt: snapshot.trailGeneratedAt,
        startedAt: snapshot.startedAt,
        updatedAt: snapshot.updatedAt,
        completedAt: snapshot.completedAt,
        lastCheckedInVenueId: snapshot.lastCheckedInVenueId,
        lastCheckedInStopOrder: snapshot.lastCheckedInStopOrder,
      ),
    );
  }

  static String _resolveName(TrailSnapshot snapshot) {
    final name = snapshot.name.trim();
    if (name.isNotEmpty) return name;
    final title = snapshot.title.trim();
    if (title.isNotEmpty) return title;
    return "Tonight's Trail";
  }

  static String _resolveDescription(TrailSnapshot snapshot) {
    final description = snapshot.description.trim();
    if (description.isNotEmpty) return description;
    final subtitle = snapshot.subtitle.trim();
    if (subtitle.isNotEmpty) return subtitle;
    return 'Generated from live DrinkSpot activity';
  }

  static TrailResult<TrailStatus> _mapStatus(TrailStatusSnapshot snapshot) {
    return switch (snapshot) {
      KnownTrailStatusSnapshot(:final value) => TrailSuccess(switch (value) {
        TrailStatusValue.draft => TrailStatus.draft,
        TrailStatusValue.published => TrailStatus.published,
        TrailStatusValue.disabled => TrailStatus.disabled,
        TrailStatusValue.archived => TrailStatus.archived,
      }),
      UnknownTrailStatusSnapshot(:final rawValue) => TrailFailure(
        TrailFailureCodes.invalidStatus,
        'Unknown trail status: $rawValue',
      ),
      MissingTrailStatusSnapshot() => const TrailFailure(
        TrailFailureCodes.invalidStatus,
        'Missing trail status.',
      ),
    };
  }

  static TrailResult<TrailType> _mapType(TrailTypeSnapshot snapshot) {
    return switch (snapshot) {
      KnownTrailTypeSnapshot(:final value) => TrailSuccess(switch (value) {
        TrailTypeValue.curated => TrailType.curated,
        TrailTypeValue.generated => TrailType.generated,
      }),
      UnknownTrailTypeSnapshot(:final rawValue) => TrailFailure(
        TrailFailureCodes.invalidStatus,
        'Unknown trail type: $rawValue',
      ),
      MissingTrailTypeSnapshot() => const TrailSuccess(TrailType.curated),
    };
  }

  static TrailResult<TrailStopState> _mapStopState(
    TrailStopProgressStateSnapshot snapshot,
  ) {
    return switch (snapshot) {
      KnownTrailStopProgressStateSnapshot(:final value) => TrailSuccess(
        switch (value) {
          TrailStopProgressStateValue.upcoming => TrailStopState.upcoming,
          TrailStopProgressStateValue.current => TrailStopState.current,
          TrailStopProgressStateValue.checkedIn => TrailStopState.checkedIn,
          TrailStopProgressStateValue.skipped => TrailStopState.skipped,
          TrailStopProgressStateValue.missed => TrailStopState.missed,
          TrailStopProgressStateValue.completed => TrailStopState.completed,
        },
      ),
      UnknownTrailStopProgressStateSnapshot(:final rawValue) =>
        rawValue.isEmpty
            ? const TrailSuccess(TrailStopState.upcoming)
            : TrailFailure(
                TrailFailureCodes.invalidProgress,
                'Unknown stop progress state: $rawValue',
              ),
    };
  }
}
