/// Supplies evaluation time for trail policies.
abstract interface class TrailClock {
  DateTime now();
}

/// Fixed clock for tests.
final class FixedTrailClock implements TrailClock {
  FixedTrailClock(this.fixedNow);

  DateTime fixedNow;

  @override
  DateTime now() => fixedNow;
}

/// Uses [DateTime.now] for production orchestration.
final class SystemTrailClock implements TrailClock {
  const SystemTrailClock();

  @override
  DateTime now() => DateTime.now();
}
