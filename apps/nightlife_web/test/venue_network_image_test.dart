import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/shared/widgets/safe_venue_branding_image.dart';
import 'package:nightlife_web/shared/widgets/venue_network_image.dart';

void main() {
  group('VenueNetworkImage', () {
    testWidgets('SafeVenueBrandingImage shows fallback for invalid URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SafeVenueBrandingImage(
            url: 'not-a-url',
            fallback: Text('fallback'),
          ),
        ),
      );

      expect(find.text('fallback'), findsOneWidget);
      expect(find.byType(VenueNetworkImage), findsNothing);
    });

    testWidgets(
      'SafeVenueBrandingImage builds VenueNetworkImage for http URL',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SafeVenueBrandingImage(
              url: 'https://example.com/logo.png',
              fallback: Text('fallback'),
            ),
          ),
        );

        expect(find.byType(VenueNetworkImage), findsOneWidget);
      },
    );
  });
}
