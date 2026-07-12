import 'package:test/test.dart';
import 'package:vex_engines/experience/application/experience_admin_content_service.dart';

void main() {
  const service = ExperienceAdminContentService();

  group('ExperienceAdminContentService', () {
    test('buildSummary preserves count fields', () {
      final summary = service.buildSummary(
        drinksCount: 4,
        dealsCount: 2,
        eventsCount: 3,
        liveDealsCount: 1,
        upcomingEventsCount: 2,
      );

      expect(summary.drinksCount, 4);
      expect(summary.liveDealsCount, 1);
      expect(summary.upcomingEventsCount, 2);
      expect(summary.unavailable, isFalse);
    });

    test('countUpcomingEvents treats null start as upcoming', () {
      final now = DateTime(2026, 7, 12, 12);
      final count = service.countUpcomingEvents(
        startDateTimes: [
          now.add(const Duration(hours: 2)),
          null,
          now.subtract(const Duration(hours: 1)),
        ],
        now: now,
      );

      expect(count, 2);
    });

    test('countUpcomingEvents matches legacy admin filter semantics', () {
      final now = DateTime(2026, 7, 12, 18, 0);
      final count = service.countUpcomingEvents(
        startDateTimes: [
          DateTime(2026, 7, 12, 20),
          DateTime(2026, 7, 11, 20),
          null,
        ],
        now: now,
      );

      expect(count, 2);
    });

    test('hasDrinks hasDeals hasEvents helpers', () {
      expect(service.hasDrinks(1), isTrue);
      expect(service.hasDeals(0), isFalse);
      expect(service.hasEvents(null), isFalse);
    });
  });
}
