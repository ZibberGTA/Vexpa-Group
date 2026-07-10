import 'package:test/test.dart';
import 'package:vex_engines/venue/domain/venue_opening_hours_entry.dart';
import 'package:vex_engines/venue/shared/venue_opening_hours_formatter.dart';

void main() {
  group('VenueOpeningHoursFormatter', () {
    test('formats weekly opening hours with closed days', () {
      final entries = VenueOpeningHoursFormatter.fromMap({
        'monday': {'open': '18:00', 'close': '02:00', 'closed': false},
        'tuesday': {'closed': true},
      }, now: DateTime(2026, 7, 6, 12));

      expect(entries, hasLength(7));
      expect(entries.first.hoursLabel, '18:00 – 02:00');
      expect(entries[1].isClosed, isTrue);
      expect(entries.first, isA<VenueOpeningHoursEntry>());
    });
  });
}
