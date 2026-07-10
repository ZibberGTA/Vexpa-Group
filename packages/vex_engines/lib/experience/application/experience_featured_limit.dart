/// Configurable featured-item limits for venue-published content.
final class ExperienceFeaturedLimit {
  const ExperienceFeaturedLimit({
    required this.maxFeatured,
    required this.limitMessage,
  });

  final int maxFeatured;
  final String limitMessage;

  static const drinks = ExperienceFeaturedLimit(
    maxFeatured: 5,
    limitMessage:
        'You can feature up to 5 drinks. Unfeature another drink first.',
  );

  static const deals = ExperienceFeaturedLimit(
    maxFeatured: 3,
    limitMessage:
        'You can feature up to 3 deals. Unfeature another deal first.',
  );

  static const events = ExperienceFeaturedLimit(
    maxFeatured: 3,
    limitMessage:
        'You can feature up to 3 events. Unfeature another event first.',
  );

  int countFeatured<T>(Iterable<T> items, bool Function(T item) isFeatured) =>
      items.where(isFeatured).length;

  String? validateAdd<T>({
    required bool wantsFeatured,
    required Iterable<T> venueItems,
    required bool Function(T item) isFeatured,
  }) {
    if (!wantsFeatured) return null;
    if (countFeatured(venueItems, isFeatured) >= maxFeatured) {
      return limitMessage;
    }
    return null;
  }

  String? validateEdit<T>({
    required bool currentlyFeatured,
    required bool wantsFeatured,
    required Iterable<T> venueItems,
    required bool Function(T item) isFeatured,
    required bool Function(T item) isSameItem,
    required T item,
  }) {
    if (!wantsFeatured || currentlyFeatured) return null;

    final otherFeatured = venueItems
        .where((candidate) => isFeatured(candidate) && !isSameItem(candidate))
        .length;
    if (otherFeatured >= maxFeatured) {
      return limitMessage;
    }
    return null;
  }

  String? validateBulkEdit<T>({
    required Iterable<T> selectedItems,
    required Iterable<T> venueItems,
    required Iterable<bool> proposedFeaturedValues,
    required bool Function(T item) isFeatured,
    required bool Function(T item) isSelected,
  }) {
    final unchangedFeatured = venueItems
        .where((item) => isFeatured(item) && !isSelected(item))
        .length;
    final proposedFeatured =
        proposedFeaturedValues.where((value) => value).length;

    if (unchangedFeatured + proposedFeatured > maxFeatured) {
      return limitMessage;
    }
    return null;
  }
}
