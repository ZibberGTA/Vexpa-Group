import '../domain/experience_gallery_content.dart';
import 'experience_deal_status.dart';
import 'experience_event_status.dart';

/// Aggregates venue content counts, summaries, and recent activity labels.
final class VenueContentSummaryService {
  const VenueContentSummaryService();

  static const recentActivityWindow = Duration(minutes: 2);
  static const recentActivityLimit = 5;

  ExperienceContentMetrics drinkMetrics<T>({
    required Iterable<T> drinks,
    required String Function(T drink) categoryLabel,
    required bool Function(T drink) available,
    required bool Function(T drink) featured,
  }) {
    final list = drinks.toList();
    return ExperienceContentMetrics(
      total: list.length,
      featured: list.where(featured).length,
      available: list.where(available).length,
      categories: {for (final d in list) categoryLabel(d)}.length,
    );
  }

  ExperienceContentMetrics dealMetrics<T>({
    required Iterable<T> deals,
    required bool Function(T deal) featured,
    required ExperienceDealManagementStatus Function(T deal) status,
  }) {
    final list = deals.toList();
    return ExperienceContentMetrics(
      total: list.length,
      featured: list.where(featured).length,
      active: list
          .where((d) => status(d) == ExperienceDealManagementStatus.active)
          .length,
      scheduled: list
          .where((d) => status(d) == ExperienceDealManagementStatus.scheduled)
          .length,
      expired: list
          .where((d) => status(d) == ExperienceDealManagementStatus.expired)
          .length,
      paused: list
          .where((d) => status(d) == ExperienceDealManagementStatus.paused)
          .length,
    );
  }

  ExperienceContentMetrics eventMetrics<T>({
    required Iterable<T> events,
    required bool Function(T event) featured,
    required ExperienceEventManagementStatus Function(T event) status,
  }) {
    final list = events.toList();
    return ExperienceContentMetrics(
      total: list.length,
      featured: list.where(featured).length,
      live: list
          .where((e) => status(e) == ExperienceEventManagementStatus.live)
          .length,
      upcoming: list
          .where((e) => status(e) == ExperienceEventManagementStatus.upcoming)
          .length,
      ended: list
          .where((e) => status(e) == ExperienceEventManagementStatus.ended)
          .length,
      draft: list
          .where((e) => status(e) == ExperienceEventManagementStatus.draft)
          .length,
    );
  }

  ExperienceContentMetrics galleryMetrics<T>({
    required Iterable<T> items,
    required bool Function(T item) isFeatured,
  }) {
    final list = items.toList();
    return ExperienceContentMetrics(
      total: list.length,
      featured: list.where(isFeatured).length,
      galleryImages: list.length,
      hasGalleryCover: list.any(isFeatured),
    );
  }

  bool isRecentlyCreated({
    required DateTime? createdAt,
    required DateTime? updatedAt,
    Duration window = recentActivityWindow,
  }) {
    if (createdAt == null || updatedAt == null) return false;
    return updatedAt.difference(createdAt) <= window;
  }

  List<ExperienceContentActivity> recentDrinkActivity<T>({
    required Iterable<T> drinks,
    required String Function(T drink) name,
    required DateTime? Function(T drink) createdAt,
    required DateTime? Function(T drink) updatedAt,
    required String Function(DateTime timestamp) formatTimestamp,
    DateTime? now,
  }) {
    return _recentActivity(
      items: drinks,
      createdAt: createdAt,
      updatedAt: updatedAt,
      kind: 'drink',
      formatTimestamp: formatTimestamp,
      titleFor: (item, isNew) {
        final drinkName = name(item);
        return isNew ? 'Drink added: $drinkName' : 'Drink updated: $drinkName';
      },
      now: now,
    );
  }

  List<ExperienceContentActivity> recentDealActivity<T>({
    required Iterable<T> deals,
    required String Function(T deal) title,
    required DateTime? Function(T deal) createdAt,
    required DateTime? Function(T deal) updatedAt,
    required ExperienceDealManagementStatus Function(T deal) status,
    required String Function(DateTime timestamp) formatTimestamp,
    DateTime? now,
  }) {
    return _recentActivity(
      items: deals,
      createdAt: createdAt,
      updatedAt: updatedAt,
      kind: 'deal',
      formatTimestamp: formatTimestamp,
      titleFor: (item, isNew) {
        final dealTitle = title(item);
        if (isNew) return 'Deal created: $dealTitle';
        return switch (status(item)) {
          ExperienceDealManagementStatus.paused => 'Deal paused: $dealTitle',
          ExperienceDealManagementStatus.expired => 'Deal expired: $dealTitle',
          _ => 'Deal updated: $dealTitle',
        };
      },
      now: now,
    );
  }

  List<ExperienceContentActivity> recentEventActivity<T>({
    required Iterable<T> events,
    required String Function(T event) title,
    required DateTime? Function(T event) createdAt,
    required DateTime? Function(T event) updatedAt,
    required String Function(DateTime timestamp) formatTimestamp,
    DateTime? now,
  }) {
    return _recentActivity(
      items: events,
      createdAt: createdAt,
      updatedAt: updatedAt,
      kind: 'event',
      formatTimestamp: formatTimestamp,
      titleFor: (item, isNew) => 'Event updated: ${title(item)}',
      now: now,
    );
  }

  List<ExperienceContentActivity> _recentActivity<T>({
    required Iterable<T> items,
    required DateTime? Function(T item) createdAt,
    required DateTime? Function(T item) updatedAt,
    required String kind,
    required String Function(T item, bool isNew) titleFor,
    required String Function(DateTime timestamp) formatTimestamp,
    DateTime? now,
  }) {
    final sorted = items.toList()
      ..sort((a, b) {
        final aTime = updatedAt(a) ??
            createdAt(a) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = updatedAt(b) ??
            createdAt(b) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    return sorted.take(recentActivityLimit).map((item) {
      final created = createdAt(item);
      final updated = updatedAt(item);
      final isNew = isRecentlyCreated(createdAt: created, updatedAt: updated);
      final timestamp = updated ?? created;

      return ExperienceContentActivity(
        title: titleFor(item, isNew),
        timestampLabel: timestamp == null
            ? 'Recently'
            : formatTimestamp(timestamp),
        kind: kind,
      );
    }).toList();
  }
}
