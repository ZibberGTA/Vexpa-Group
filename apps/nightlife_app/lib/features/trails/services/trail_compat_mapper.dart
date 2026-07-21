import 'package:vex_core/trails/trails.dart';
import 'package:vex_engines/trail/trail_engine.dart' as vex;

import '../models/trail_model.dart';

/// Converts between mobile UI models and VexTrail domain / VexCore snapshots.
abstract final class TrailCompatMapper {
  static DrinkSpotTrailModel? fromSnapshot(TrailSnapshot? snapshot) {
    if (snapshot == null) return null;
    final domain = vex.TrailPersistenceMapper.mapTrailOrNull(snapshot);
    if (domain == null) return null;
    return fromDomain(domain);
  }

  static DrinkSpotTrailModel fromDomain(vex.Trail trail) {
    return DrinkSpotTrailModel(
      id: trail.id,
      name: trail.name,
      description: trail.description,
      bannerImageUrl: trail.bannerImageUrl,
      status: _mobileStatus(trail.status),
      published: trail.published,
      area: trail.area,
      availabilityStart: trail.availabilityStart,
      availabilityEnd: trail.availabilityEnd,
      estimatedDuration: Duration(minutes: trail.estimatedDurationMinutes),
      estimatedWalkingDistance: trail.estimatedWalkingDistance,
      averageRating: trail.averageRating,
      venueCount: trail.venueCount,
      trailType: _mobileType(trail.trailType),
      generatedAt: trail.generatedAt,
      stops: trail.stops.map(fromDomainStop).toList(),
    );
  }

  static vex.Trail toDomain(DrinkSpotTrailModel trail) {
    return vex.Trail(
      id: trail.id,
      name: trail.name,
      description: trail.description,
      bannerImageUrl: trail.bannerImageUrl,
      status: _domainStatus(trail.status),
      published: trail.published,
      area: trail.area,
      availabilityStart: trail.availabilityStart,
      availabilityEnd: trail.availabilityEnd,
      estimatedDurationMinutes: trail.estimatedDuration.inMinutes,
      estimatedWalkingDistance: trail.estimatedWalkingDistance,
      averageRating: trail.averageRating,
      venueCount: trail.venueCount,
      trailType: _domainType(trail.trailType),
      generatedAt: trail.generatedAt,
      stops: trail.stops.map(toDomainStop).toList(),
    );
  }

  static vex.TrailStop toDomainStop(TrailStopModel stop) {
    return vex.TrailStop(
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

  static TrailStopModel fromDomainStop(vex.TrailStop stop) {
    return TrailStopModel(
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

  static TrailProgressModel fromDomainProgress(vex.TrailProgress progress) {
    return TrailProgressModel(
      trailId: progress.trailId,
      started: progress.started,
      completed: progress.completed,
      currentStop: progress.currentStopIndex,
      checkedInStops: progress.checkedInStopOrders,
      stopStates: {
        for (final entry in progress.stopStates.entries)
          entry.key: _mobileStopState(entry.value),
      },
      trailGeneratedAt: progress.trailGeneratedAt,
    );
  }

  static vex.TrailProgress toDomainProgress(TrailProgressModel progress) {
    return vex.TrailProgress(
      trailId: progress.trailId,
      started: progress.started,
      completed: progress.completed,
      currentStopIndex: progress.currentStop,
      checkedInStopOrders: progress.checkedInStops,
      stopStates: {
        for (final entry in progress.stopStates.entries)
          entry.key: _domainStopState(entry.value),
      },
      trailGeneratedAt: progress.trailGeneratedAt,
    );
  }

  static vex.TrailProgress initialDomainProgress(vex.Trail trail) {
    return vex.TrailProgress(
      trailId: trail.id,
      started: false,
      completed: false,
      currentStopIndex: 0,
      checkedInStopOrders: const {},
      stopStates: vex.TrailProgressStatePolicy.initialStopStates(trail),
      trailGeneratedAt: trail.generatedAt,
    );
  }

  static TrailTypeValue domainTrailTypeValue(TrailType type) {
    return switch (type) {
      TrailType.curated => TrailTypeValue.curated,
      TrailType.generated => TrailTypeValue.generated,
    };
  }

  static vex.TrailGenerationCandidate generationCandidateFromVenue({
    required String venueId,
    required Map<String, dynamic> data,
  }) {
    final featureTagsRaw = data['featureTags'];
    final featureTags = featureTagsRaw is List
        ? featureTagsRaw.map((item) => item.toString()).toList()
        : const <String>[];

    return vex.TrailGenerationCandidate(
      venueId: venueId,
      name: (data['name'] ?? 'Venue').toString(),
      address: (data['address'] ?? '').toString(),
      bannerImageUrl:
          (data['bannerImageUrl'] ?? data['imageUrl'] ?? '').toString(),
      logoUrl: (data['logoUrl'] ?? '').toString(),
      crowdLevel: (data['crowdLevel'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      hasDeals: data['hasDeals'] == true,
      featureTags: featureTags,
    );
  }

  static int? nextUpcomingStopIndex({
    required DrinkSpotTrailModel trail,
    required int afterIndex,
    required vex.TrailProgress progress,
  }) {
    for (var index = afterIndex + 1; index < trail.stops.length; index++) {
      final state = progress.stopStates[trail.stops[index].order];
      if (state == null ||
          state == vex.TrailStopState.upcoming ||
          state == vex.TrailStopState.current) {
        return index;
      }
    }
    return null;
  }

  static DrinkSpotTrailModel? visibleTrailFromSnapshots(
    List<TrailSnapshot> snapshots,
    String preferredTrailId,
  ) {
    DrinkSpotTrailModel? firstVisibleTrail;
    for (final snapshot in snapshots) {
      final trail = fromSnapshot(snapshot);
      if (trail == null || !trail.isVisible) continue;
      firstVisibleTrail ??= trail;
      if (trail.id == preferredTrailId) return trail;
    }
    return firstVisibleTrail;
  }

  static TrailStatus _mobileStatus(vex.TrailStatus status) {
    return switch (status) {
      vex.TrailStatus.draft => TrailStatus.draft,
      vex.TrailStatus.published => TrailStatus.published,
      vex.TrailStatus.disabled => TrailStatus.disabled,
      vex.TrailStatus.archived => TrailStatus.archived,
    };
  }

  static vex.TrailStatus _domainStatus(TrailStatus status) {
    return switch (status) {
      TrailStatus.draft => vex.TrailStatus.draft,
      TrailStatus.published => vex.TrailStatus.published,
      TrailStatus.disabled => vex.TrailStatus.disabled,
      TrailStatus.archived => vex.TrailStatus.archived,
    };
  }

  static TrailType _mobileType(vex.TrailType type) {
    return switch (type) {
      vex.TrailType.curated => TrailType.curated,
      vex.TrailType.generated => TrailType.generated,
    };
  }

  static vex.TrailType _domainType(TrailType type) {
    return switch (type) {
      TrailType.curated => vex.TrailType.curated,
      TrailType.generated => vex.TrailType.generated,
    };
  }

  static TrailStopProgressState _mobileStopState(vex.TrailStopState state) {
    return switch (state) {
      vex.TrailStopState.upcoming => TrailStopProgressState.upcoming,
      vex.TrailStopState.current => TrailStopProgressState.current,
      vex.TrailStopState.checkedIn => TrailStopProgressState.checkedIn,
      vex.TrailStopState.skipped => TrailStopProgressState.skipped,
      vex.TrailStopState.missed => TrailStopProgressState.missed,
      vex.TrailStopState.completed => TrailStopProgressState.completed,
    };
  }

  static vex.TrailStopState _domainStopState(TrailStopProgressState state) {
    return switch (state) {
      TrailStopProgressState.upcoming => vex.TrailStopState.upcoming,
      TrailStopProgressState.current => vex.TrailStopState.current,
      TrailStopProgressState.checkedIn => vex.TrailStopState.checkedIn,
      TrailStopProgressState.skipped => vex.TrailStopState.skipped,
      TrailStopProgressState.missed => vex.TrailStopState.missed,
      TrailStopProgressState.completed => vex.TrailStopState.completed,
    };
  }
}
