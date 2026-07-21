/// Injectable random source for generation policies (tests use deterministic values).
abstract interface class TrailRandomSource {
  double nextDouble();
  int nextInt(int max);
}

/// Deterministic random source for tests.
final class SeededTrailRandomSource implements TrailRandomSource {
  SeededTrailRandomSource(this.seed);

  int seed;

  @override
  double nextDouble() {
    seed = (seed * 9301 + 49297) % 233280;
    return seed / 233280;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) return 0;
    return (nextDouble() * max).floor();
  }
}
