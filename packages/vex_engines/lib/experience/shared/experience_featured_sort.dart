/// Sorts venue-published content with featured items first.
List<T> sortExperienceFeaturedFirst<T>(
  List<T> items,
  bool Function(T item) isFeatured,
  int Function(T a, T b) compare,
) {
  final featured = <T>[];
  final nonFeatured = <T>[];

  for (final item in items) {
    if (isFeatured(item)) {
      featured.add(item);
    } else {
      nonFeatured.add(item);
    }
  }

  featured.sort(compare);
  nonFeatured.sort(compare);
  return [...featured, ...nonFeatured];
}
