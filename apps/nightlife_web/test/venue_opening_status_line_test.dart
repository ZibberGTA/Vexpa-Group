import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nightlife_web/features/venue/widgets/venue_opening_status_line.dart';

void main() {
  group('VenueOpeningStatusLine', () {
    testWidgets('shows single closed line with next opening detail', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueOpeningStatusLine(
              openingHours: {
                'wednesday': {'closed': true},
                'thursday': {'closed': false, 'open': '12:00', 'close': '23:00'},
              },
            ),
          ),
        ),
      );

      expect(find.text('Closed'), findsOneWidget);
      expect(find.textContaining('Opens'), findsOneWidget);
      expect(find.text('Open now'), findsNothing);
    });
  });
}
