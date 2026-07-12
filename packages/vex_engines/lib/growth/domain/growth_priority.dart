/// Priority ordering for growth recommendations.
enum GrowthPriority {
  critical,
  high,
  medium,
  low;

  int get sortOrder => switch (this) {
    GrowthPriority.critical => 0,
    GrowthPriority.high => 1,
    GrowthPriority.medium => 2,
    GrowthPriority.low => 3,
  };
}
