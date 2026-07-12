import 'experience_featured_limit.dart';

/// Featured flags, cover selection, and duplicate copy rules for venue content.
final class VenueFeaturedContentService {
  const VenueFeaturedContentService();

  static const drinksLimit = ExperienceFeaturedLimit.drinks;
  static const dealsLimit = ExperienceFeaturedLimit.deals;
  static const eventsLimit = ExperienceFeaturedLimit.events;

  /// Appends " Copy" to a duplicated item title unless already present.
  String duplicateCopyTitle(String sourceTitle) {
    final trimmed = sourceTitle.trim();
    if (trimmed.endsWith(' Copy')) return trimmed;
    return '$trimmed Copy';
  }

  /// Duplicate deals start paused and unfeatured.
  DuplicateDealDefaults duplicateDealDefaults({
    required DateTime? sourceStart,
    required DateTime? sourceEnd,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final start = sourceStart ?? clock;
    return DuplicateDealDefaults(
      isActive: false,
      featured: false,
      startDateTime: start,
      endDateTime: sourceEnd ?? start.add(const Duration(days: 30)),
    );
  }

  /// Duplicate events start as draft copies (inactive, unfeatured).
  DuplicateEventDefaults duplicateEventDefaults() {
    return const DuplicateEventDefaults(isActive: false, featured: false);
  }

  /// Returns the id of the gallery cover item, if any.
  String? selectCoverItemId<T>({
    required Iterable<T> items,
    required String Function(T item) id,
    required bool Function(T item) isFeatured,
  }) {
    for (final item in items) {
      if (isFeatured(item)) return id(item);
    }
    return null;
  }

  /// Applies cover selection by setting featured=true only on [coverItemId].
  List<T> applyCoverSelection<T>({
    required List<T> items,
    required String coverItemId,
    required T Function(T item, {required bool featured}) copyWithFeatured,
    required String Function(T item) id,
  }) {
    return items
        .map(
          (item) => copyWithFeatured(
            item,
            featured: id(item) == coverItemId,
          ),
        )
        .toList();
  }

  /// Ordered gallery image URLs for denormalized venue document sync.
  List<String> gallerySyncUrls<T>({
    required Iterable<T> items,
    required String Function(T item) imageUrl,
    required bool Function(T item) hasNonEmptyUrl,
  }) {
    return items.where(hasNonEmptyUrl).map(imageUrl).toList();
  }
}

final class DuplicateDealDefaults {
  const DuplicateDealDefaults({
    required this.isActive,
    required this.featured,
    required this.startDateTime,
    required this.endDateTime,
  });

  final bool isActive;
  final bool featured;
  final DateTime startDateTime;
  final DateTime endDateTime;
}

final class DuplicateEventDefaults {
  const DuplicateEventDefaults({
    required this.isActive,
    required this.featured,
  });

  final bool isActive;
  final bool featured;
}
