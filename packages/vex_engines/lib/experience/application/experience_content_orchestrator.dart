import '../shared/experience_featured_sort.dart';
import 'experience_deal_visibility.dart';
import 'experience_drink_visibility.dart';
import 'experience_event_visibility.dart';

/// In-memory orchestration for venue-published customer content.
final class ExperienceContentOrchestrator {
  const ExperienceContentOrchestrator();

  List<T> filterPublicDrinks<T>(
    Iterable<T> drinks, {
    required bool Function(T drink) isDeleted,
    required bool Function(T drink) available,
  }) =>
      drinks
          .where(
            (drink) => ExperienceDrinkVisibility.isPublicVisible(
              isDeleted: isDeleted(drink),
              available: available(drink),
            ),
          )
          .toList();

  List<T> filterPublicVisibleDeals<T>(
    Iterable<T> deals, {
    required bool Function(T deal) isDeleted,
    required bool Function(T deal) isActive,
    required DateTime? Function(T deal) startDateTime,
    required DateTime? Function(T deal) endDateTime,
    required DateTime? Function(T deal) effectiveEndDateTime,
    DateTime? now,
  }) =>
      deals
          .where(
            (deal) => ExperienceDealVisibility.isPublicVisible(
              isDeleted: isDeleted(deal),
              isActive: isActive(deal),
              startDateTime: startDateTime(deal),
              endDateTime: endDateTime(deal),
              effectiveEndDateTime: effectiveEndDateTime(deal),
              now: now,
            ),
          )
          .toList();

  List<T> filterPublicCurrentDeals<T>(
    Iterable<T> deals, {
    required bool Function(T deal) isDeleted,
    required bool Function(T deal) isActive,
    required DateTime? Function(T deal) startDateTime,
    required DateTime? Function(T deal) endDateTime,
    required DateTime? Function(T deal) effectiveEndDateTime,
    DateTime? now,
  }) =>
      deals
          .where(
            (deal) => ExperienceDealVisibility.isPublicCurrent(
              isDeleted: isDeleted(deal),
              isActive: isActive(deal),
              startDateTime: startDateTime(deal),
              endDateTime: endDateTime(deal),
              effectiveEndDateTime: effectiveEndDateTime(deal),
              now: now,
            ),
          )
          .toList();

  List<T> filterPublicUpcomingDeals<T>(
    Iterable<T> deals, {
    required bool Function(T deal) isDeleted,
    required bool Function(T deal) isActive,
    required DateTime? Function(T deal) startDateTime,
    required DateTime? Function(T deal) endDateTime,
    required DateTime? Function(T deal) effectiveEndDateTime,
    DateTime? now,
  }) =>
      deals
          .where(
            (deal) => ExperienceDealVisibility.isPublicUpcoming(
              isDeleted: isDeleted(deal),
              isActive: isActive(deal),
              startDateTime: startDateTime(deal),
              endDateTime: endDateTime(deal),
              effectiveEndDateTime: effectiveEndDateTime(deal),
              now: now,
            ),
          )
          .toList();

  List<T> filterPublicVisibleEvents<T>(
    Iterable<T> events, {
    required bool Function(T event) isDeleted,
    required bool Function(T event) isActive,
    required DateTime Function(T event) startDateTime,
    required DateTime Function(T event) endDateTime,
    DateTime? now,
  }) =>
      events
          .where(
            (event) => ExperienceEventVisibility.isPublicVisible(
              isDeleted: isDeleted(event),
              isActive: isActive(event),
              startDateTime: startDateTime(event),
              endDateTime: endDateTime(event),
              now: now,
            ),
          )
          .toList();

  List<T> filterPublicCurrentEvents<T>(
    Iterable<T> events, {
    required bool Function(T event) isDeleted,
    required bool Function(T event) isActive,
    required DateTime Function(T event) startDateTime,
    required DateTime Function(T event) endDateTime,
    DateTime? now,
  }) =>
      events
          .where(
            (event) => ExperienceEventVisibility.isPublicCurrent(
              isDeleted: isDeleted(event),
              isActive: isActive(event),
              startDateTime: startDateTime(event),
              endDateTime: endDateTime(event),
              now: now,
            ),
          )
          .toList();

  List<T> filterPublicUpcomingEvents<T>(
    Iterable<T> events, {
    required bool Function(T event) isDeleted,
    required bool Function(T event) isActive,
    required DateTime Function(T event) startDateTime,
    required DateTime Function(T event) endDateTime,
    DateTime? now,
  }) =>
      events
          .where(
            (event) => ExperienceEventVisibility.isPublicUpcoming(
              isDeleted: isDeleted(event),
              isActive: isActive(event),
              startDateTime: startDateTime(event),
              endDateTime: endDateTime(event),
              now: now,
            ),
          )
          .toList();

  List<T> sortFeaturedFirst<T>(
    List<T> items, {
    required bool Function(T item) isFeatured,
    required int Function(T a, T b) compare,
  }) =>
      sortExperienceFeaturedFirst(items, isFeatured, compare);
}
