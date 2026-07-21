import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nightlife_web/features/venue/widgets/venue_crowd_status_badge.dart';

void main() {
  group('VenueCrowdStatusBadge', () {
    testWidgets('shows customer crowd wording in preview mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VenueCrowdStatusBadge(
              venueId: 'venue-1',
              crowdLevel: 'quiet',
              previewOnly: true,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Relaxed'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });
  });
}
