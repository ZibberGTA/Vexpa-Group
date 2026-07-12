import 'experience_deal_status.dart';
import 'experience_deal_visibility.dart';
import 'experience_drink_visibility.dart';
import 'experience_event_visibility.dart';

/// Availability and pause eligibility across drinks, deals, events, and media.
final class VenueAvailabilityService {
  const VenueAvailabilityService();

  bool isDrinkPublicVisible({
    required bool isDeleted,
    required bool available,
  }) =>
      ExperienceDrinkVisibility.isPublicVisible(
        isDeleted: isDeleted,
        available: available,
      );

  bool isDealPublicCurrent({
    required bool isDeleted,
    required bool isActive,
    required DateTime? startDateTime,
    required DateTime? endDateTime,
    required DateTime? effectiveEndDateTime,
    DateTime? now,
  }) =>
      ExperienceDealVisibility.isPublicCurrent(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        effectiveEndDateTime: effectiveEndDateTime,
        now: now,
      );

  bool isDealPublicUpcoming({
    required bool isDeleted,
    required bool isActive,
    required DateTime? startDateTime,
    required DateTime? endDateTime,
    required DateTime? effectiveEndDateTime,
    DateTime? now,
  }) =>
      ExperienceDealVisibility.isPublicUpcoming(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        effectiveEndDateTime: effectiveEndDateTime,
        now: now,
      );

  bool isEventPublicVisible({
    required bool isDeleted,
    required bool isActive,
    required DateTime startDateTime,
    required DateTime endDateTime,
    DateTime? now,
  }) =>
      ExperienceEventVisibility.isPublicVisible(
        isDeleted: isDeleted,
        isActive: isActive,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        now: now,
      );

  /// Active gallery/brand media rows pass status and visibility checks.
  bool isMediaActive({
    required String status,
    required bool visible,
  }) =>
      status == 'active' && visible;

  /// Deals in active or scheduled management status can be paused.
  bool isDealPausable(ExperienceDealManagementStatus status) {
    return status == ExperienceDealManagementStatus.active ||
        status == ExperienceDealManagementStatus.scheduled;
  }

  /// Filters items to those considered active for management library tabs.
  List<T> filterActiveMedia<T>({
    required Iterable<T> items,
    required String Function(T item) status,
    required bool Function(T item) visible,
  }) {
    return items
        .where((item) => isMediaActive(status: status(item), visible: visible(item)))
        .toList();
  }
}
