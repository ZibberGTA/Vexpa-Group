import 'package:test/test.dart';
import 'package:vex_engines/venue/shared/venue_opening_status_presentation.dart';

void main() {
  group('VenueOpeningStatusPresentation', () {
    test('returns closed with next opening day and time', () {
      // Wednesday 10:00 — venue closed today, opens Thursday at 12:00.
      final now = DateTime(2026, 7, 15, 10, 0);

      final status = VenueOpeningStatusPresentation.resolve(
        {
          'wednesday': {'closed': true},
          'thursday': {'closed': false, 'open': '12:00', 'close': '23:00'},
        },
        now: now,
      );

      expect(status.isOpen, isFalse);
      expect(status.label, 'Closed • Opens tomorrow 12:00 PM');
    });

    test('returns open until close time for same-day hours', () {
      final now = DateTime(2026, 7, 15, 20, 0);

      final status = VenueOpeningStatusPresentation.resolve(
        {
          'wednesday': {'closed': false, 'open': '18:00', 'close': '02:00'},
        },
        now: now,
      );

      expect(status.isOpen, isTrue);
      expect(status.label, 'Open • Closes 2:00 AM');
    });
  });
}
