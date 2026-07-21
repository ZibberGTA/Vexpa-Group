import 'package:vex_engines/trail/trail_engine.dart';

Trail buildTrail({
  String id = 'trail-1',
  String name = 'Test Trail',
  TrailStatus status = TrailStatus.published,
  bool published = true,
  DateTime? availabilityStart,
  DateTime? availabilityEnd,
  List<TrailStop>? stops,
  TrailType trailType = TrailType.curated,
  DateTime? generatedAt,
  String bannerImageUrl = 'https://example.com/banner.jpg',
  int? venueCount,
}) {
  final start = availabilityStart ?? DateTime(2026, 7, 18, 19);
  final end = availabilityEnd ?? DateTime(2026, 7, 18, 23);
  final route =
      stops ??
      [
        TrailStop(
          venueId: 'v1',
          venueName: 'Venue 1',
          address: 'Addr 1',
          bannerImageUrl: '',
          logoUrl: '',
          order: 1,
          score: 10,
          arriveAt: start,
          leaveAt: start.add(const Duration(hours: 1)),
        ),
        TrailStop(
          venueId: 'v2',
          venueName: 'Venue 2',
          address: 'Addr 2',
          bannerImageUrl: '',
          logoUrl: '',
          order: 2,
          score: 8,
          arriveAt: start.add(const Duration(hours: 1)),
          leaveAt: end,
        ),
      ];

  return Trail(
    id: id,
    name: name,
    description: 'Description',
    bannerImageUrl: bannerImageUrl,
    status: status,
    published: published,
    area: 'City',
    availabilityStart: start,
    availabilityEnd: end,
    estimatedDurationMinutes: end.difference(start).inMinutes,
    estimatedWalkingDistance: 500,
    averageRating: 4.2,
    venueCount: venueCount ?? route.length,
    trailType: trailType,
    generatedAt: generatedAt ?? DateTime(2026, 7, 18, 12),
    stops: route,
  );
}

TrailProgress buildProgress({
  String trailId = 'trail-1',
  bool started = true,
  bool completed = false,
  int currentStopIndex = 0,
  Map<int, TrailStopState>? stopStates,
  DateTime? trailGeneratedAt,
}) {
  return TrailProgress(
    trailId: trailId,
    started: started,
    completed: completed,
    currentStopIndex: currentStopIndex,
    checkedInStopOrders: const {},
    stopStates:
        stopStates ?? {1: TrailStopState.current, 2: TrailStopState.upcoming},
    trailGeneratedAt: trailGeneratedAt ?? DateTime(2026, 7, 18, 12),
  );
}
