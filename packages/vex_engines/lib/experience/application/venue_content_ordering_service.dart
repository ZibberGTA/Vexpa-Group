import '../domain/experience_gallery_content.dart';
import '../shared/experience_featured_sort.dart';
import 'experience_deal_status.dart';

/// Sort column identifiers for deal management tables.
enum ExperienceDealSortColumn {
  title,
  dealType,
  startDate,
  endDate,
  status,
  featured,
}

enum ExperienceSortDirection {
  ascending,
  descending,
}

/// Deal table sort state for management surfaces.
final class ExperienceDealTableSort {
  const ExperienceDealTableSort({
    this.column = ExperienceDealSortColumn.title,
    this.direction = ExperienceSortDirection.ascending,
  });

  final ExperienceDealSortColumn column;
  final ExperienceSortDirection direction;

  ExperienceDealTableSort toggleColumn(ExperienceDealSortColumn column) {
    if (this.column == column) {
      return ExperienceDealTableSort(
        column: column,
        direction: direction == ExperienceSortDirection.ascending
            ? ExperienceSortDirection.descending
            : ExperienceSortDirection.ascending,
      );
    }

    return ExperienceDealTableSort(
      column: column,
      direction: _defaultDirection(column),
    );
  }

  static ExperienceSortDirection _defaultDirection(
    ExperienceDealSortColumn column,
  ) {
    return ExperienceSortDirection.ascending;
  }
}

/// Sort column identifiers for drink management tables.
enum ExperienceDrinkSortColumn {
  name,
  category,
  price,
  available,
  featured,
}

/// Drink table sort state for management surfaces.
final class ExperienceDrinkTableSort {
  const ExperienceDrinkTableSort({
    this.column = ExperienceDrinkSortColumn.name,
    this.direction = ExperienceSortDirection.ascending,
  });

  final ExperienceDrinkSortColumn column;
  final ExperienceSortDirection direction;

  ExperienceDrinkTableSort toggleColumn(ExperienceDrinkSortColumn column) {
    if (this.column == column) {
      return ExperienceDrinkTableSort(
        column: column,
        direction: direction == ExperienceSortDirection.ascending
            ? ExperienceSortDirection.descending
            : ExperienceSortDirection.ascending,
      );
    }

    return ExperienceDrinkTableSort(
      column: column,
      direction: ExperienceSortDirection.ascending,
    );
  }
}

/// Centralizes display ordering for drinks, deals, events, and gallery media.
final class VenueContentOrderingService {
  const VenueContentOrderingService();

  /// Featured items first, then [compare] within each group.
  List<T> sortFeaturedFirst<T>(
    List<T> items,
    bool Function(T item) isFeatured,
    int Function(T a, T b) compare,
  ) =>
      sortExperienceFeaturedFirst(items, isFeatured, compare);

  /// Public deal list: current before upcoming, then by start datetime.
  List<T> sortPublicDeals<T>({
    required List<T> deals,
    required bool Function(T deal) isUpcoming,
    required DateTime? Function(T deal) startDateTime,
    DateTime? now,
  }) {
    final sorted = List<T>.from(deals);
    sorted.sort((a, b) {
      final aUpcoming = isUpcoming(a);
      final bUpcoming = isUpcoming(b);
      if (aUpcoming != bUpcoming) return aUpcoming ? 1 : -1;
      return (startDateTime(a) ?? DateTime(2100)).compareTo(
        startDateTime(b) ?? DateTime(2100),
      );
    });
    return sorted;
  }

  /// Events sorted by start datetime ascending.
  List<T> sortEventsByStart<T>({
    required List<T> events,
    required DateTime Function(T event) startDateTime,
  }) {
    final sorted = List<T>.from(events);
    sorted.sort((a, b) => startDateTime(a).compareTo(startDateTime(b)));
    return sorted;
  }

  /// Gallery media: featured → sortOrder → uploadedAt ascending.
  int compareGalleryMedia({
    required bool aFeatured,
    required bool bFeatured,
    required int aSortOrder,
    required int bSortOrder,
    required DateTime? aUploadedAt,
    required DateTime? bUploadedAt,
  }) {
    if (aFeatured != bFeatured) return aFeatured ? -1 : 1;
    final order = aSortOrder.compareTo(bSortOrder);
    if (order != 0) return order;
    final aTime = aUploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = bUploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aTime.compareTo(bTime);
  }

  /// Brand assets: current first, logo before banner, newest upload first.
  int compareBrandMedia({
    required bool aIsCurrent,
    required bool bIsCurrent,
    required bool aIsLogo,
    required bool bIsLogo,
    required DateTime? aUploadedAt,
    required DateTime? bUploadedAt,
  }) {
    if (aIsCurrent != bIsCurrent) return aIsCurrent ? -1 : 1;
    if (aIsLogo != bIsLogo) return aIsLogo ? -1 : 1;
    final aTime = aUploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = bUploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  /// Deal management table ordering with featured-first grouping.
  List<T> sortDealsForTable<T>({
    required List<T> deals,
    required ExperienceDealTableSort sort,
    required bool Function(T deal) isFeatured,
    required String Function(T deal) title,
    required String Function(T deal) dealTypeLabel,
    required DateTime? Function(T deal) startDateTime,
    required DateTime? Function(T deal) endDateTime,
    required ExperienceDealManagementStatus Function(T deal) status,
  }) {
    return sortFeaturedFirst(
      deals,
      isFeatured,
      (a, b) => compareDealsForTable(
        a: a,
        b: b,
        sort: sort,
        isFeatured: isFeatured,
        title: title,
        dealTypeLabel: dealTypeLabel,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        status: status,
      ),
    );
  }

  int compareDealsForTable<T>({
    required T a,
    required T b,
    required ExperienceDealTableSort sort,
    required bool Function(T deal) isFeatured,
    required String Function(T deal) title,
    required String Function(T deal) dealTypeLabel,
    required DateTime? Function(T deal) startDateTime,
    required DateTime? Function(T deal) endDateTime,
    required ExperienceDealManagementStatus Function(T deal) status,
  }) {
    final comparison = switch (sort.column) {
      ExperienceDealSortColumn.title =>
        title(a).toLowerCase().compareTo(title(b).toLowerCase()),
      ExperienceDealSortColumn.dealType => dealTypeLabel(a)
          .toLowerCase()
          .compareTo(dealTypeLabel(b).toLowerCase()),
      ExperienceDealSortColumn.startDate =>
        _compareDate(startDateTime(a), startDateTime(b)),
      ExperienceDealSortColumn.endDate =>
        _compareDate(endDateTime(a), endDateTime(b)),
      ExperienceDealSortColumn.status =>
        _statusLabel(status(a)).compareTo(_statusLabel(status(b))),
      ExperienceDealSortColumn.featured =>
        _compareBool(a: isFeatured(a), b: isFeatured(b), trueFirst: true),
    };

    if (comparison == 0) {
      final titleCompare =
          title(a).toLowerCase().compareTo(title(b).toLowerCase());
      if (titleCompare == 0) return 0;
      return sort.direction == ExperienceSortDirection.ascending
          ? titleCompare
          : -titleCompare;
    }

    return sort.direction == ExperienceSortDirection.ascending
        ? comparison
        : -comparison;
  }

  /// Drink management table ordering with featured-first grouping.
  List<T> sortDrinksForTable<T>({
    required List<T> drinks,
    required ExperienceDrinkTableSort sort,
    required bool Function(T drink) isFeatured,
    required String Function(T drink) name,
    required String Function(T drink) categoryLabel,
    required double Function(T drink) price,
    required bool Function(T drink) available,
  }) {
    return sortFeaturedFirst(
      drinks,
      isFeatured,
      (a, b) => compareDrinksForTable(
        a: a,
        b: b,
        sort: sort,
        name: name,
        categoryLabel: categoryLabel,
        price: price,
        available: available,
        isFeatured: isFeatured,
      ),
    );
  }

  int compareDrinksForTable<T>({
    required T a,
    required T b,
    required ExperienceDrinkTableSort sort,
    required String Function(T drink) name,
    required String Function(T drink) categoryLabel,
    required double Function(T drink) price,
    required bool Function(T drink) available,
    required bool Function(T drink) isFeatured,
  }) {
    final comparison = switch (sort.column) {
      ExperienceDrinkSortColumn.name =>
        name(a).toLowerCase().compareTo(name(b).toLowerCase()),
      ExperienceDrinkSortColumn.category => categoryLabel(a)
          .toLowerCase()
          .compareTo(categoryLabel(b).toLowerCase()),
      ExperienceDrinkSortColumn.price => price(a).compareTo(price(b)),
      ExperienceDrinkSortColumn.available =>
        _compareBool(a: available(a), b: available(b), trueFirst: true),
      ExperienceDrinkSortColumn.featured =>
        _compareBool(a: isFeatured(a), b: isFeatured(b), trueFirst: true),
    };

    if (comparison == 0) {
      final nameCompare = name(a).toLowerCase().compareTo(name(b).toLowerCase());
      if (nameCompare == 0) return 0;
      return sort.direction == ExperienceSortDirection.ascending
          ? nameCompare
          : -nameCompare;
    }

    return sort.direction == ExperienceSortDirection.ascending
        ? comparison
        : -comparison;
  }

  static int _compareDate(DateTime? a, DateTime? b) {
    final aMillis = a?.millisecondsSinceEpoch ?? 0;
    final bMillis = b?.millisecondsSinceEpoch ?? 0;
    return aMillis.compareTo(bMillis);
  }

  static int _compareBool({
    required bool a,
    required bool b,
    required bool trueFirst,
  }) {
    if (a == b) return 0;
    if (trueFirst) return a ? -1 : 1;
    return a ? 1 : -1;
  }

  static String _statusLabel(ExperienceDealManagementStatus status) {
    return switch (status) {
      ExperienceDealManagementStatus.active => 'Active',
      ExperienceDealManagementStatus.scheduled => 'Scheduled',
      ExperienceDealManagementStatus.expired => 'Expired',
      ExperienceDealManagementStatus.paused => 'Paused',
    };
  }

  /// Sorts gallery media items in place using standard gallery ordering.
  void sortGalleryItems(List<ExperienceMediaSortKey> items) {
    items.sort((a, b) => compareGalleryMedia(
          aFeatured: a.featured,
          bFeatured: b.featured,
          aSortOrder: a.sortOrder,
          bSortOrder: b.sortOrder,
          aUploadedAt: a.uploadedAt,
          bUploadedAt: b.uploadedAt,
        ));
  }

  /// Sorts brand asset rows: current first, logo before banner, newest first.
  void sortBrandMediaItems(List<ExperienceMediaSortKey> items) {
    items.sort((a, b) => compareBrandMedia(
          aIsCurrent: a.isCurrent,
          bIsCurrent: b.isCurrent,
          aIsLogo: a.mediaKind == 'logo',
          bIsLogo: b.mediaKind == 'logo',
          aUploadedAt: a.uploadedAt,
          bUploadedAt: b.uploadedAt,
        ));
  }
}
