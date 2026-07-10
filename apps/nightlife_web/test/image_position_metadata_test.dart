import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venues/data/venue_image_field_parser.dart';
import 'package:nightlife_web/features/venues/models/image_position_metadata.dart';
import 'package:nightlife_web/features/venues/models/venue_model.dart';
import 'package:nightlife_web/shared/widgets/positioned_venue_image.dart';

void main() {
  group('ImagePositionMetadata', () {
    test('serialises and deserialises focal point and scale', () {
      const metadata = ImagePositionMetadata(
        focalPointX: 0.25,
        focalPointY: 0.75,
        scale: 1.8,
        cropX: 0.25,
        cropY: 0.75,
        aspectRatio: 2.85,
      );

      final restored = ImagePositionMetadata.fromMap(metadata.toMap());

      expect(restored.focalPointX, 0.25);
      expect(restored.focalPointY, 0.75);
      expect(restored.scale, 1.8);
      expect(restored.aspectRatio, 2.85);
      expect(restored.alignment, const Alignment(-0.5, 0.5));
    });

    test('defaults to centred cover when map is empty', () {
      expect(ImagePositionMetadata.fromMap(null), ImagePositionMetadata.defaults);
      expect(ImagePositionMetadata.fromMap({}).alignment, Alignment.center);
    });
  });

  group('VenueImageFieldParser image positions', () {
    test('parses banner and logo position fields', () {
      final map = {
        'bannerImagePosition': {
          'focalPointX': 0.4,
          'focalPointY': 0.6,
          'scale': 2,
        },
        'logoImagePosition': {
          'focalPointX': 0.55,
          'focalPointY': 0.45,
          'scale': 1.2,
        },
      };

      final banner = VenueImageFieldParser.resolveBannerImagePosition(map);
      final logo = VenueImageFieldParser.resolveLogoImagePosition(map);

      expect(banner?.focalPointX, 0.4);
      expect(logo?.scale, 1.2);
    });

    test('parses gallery cover positions map', () {
      final positions = VenueImageFieldParser.resolveGalleryImagePositions({
        'galleryImagePositions': {
          '0': {'focalPointX': 0.3, 'focalPointY': 0.7, 'scale': 1.5},
        },
      });

      expect(positions['0']?.focalPointX, 0.3);
      expect(positions['0']?.scale, 1.5);
    });
  });

  group('VenueModel image positions', () {
    test('maps position metadata from Firestore document', () {
      final venue = VenueModel.fromMap('venue-1', {
        'name': 'Test Venue',
        'bannerImageUrl': 'https://example.com/banner.jpg',
        'bannerImagePosition': {'focalPointX': 0.2, 'focalPointY': 0.8, 'scale': 1.6},
        'logoImagePosition': {'focalPointX': 0.5, 'focalPointY': 0.5, 'scale': 1},
        'galleryImagePositions': {
          '0': {'focalPointX': 0.35, 'focalPointY': 0.65, 'scale': 2.2},
        },
      });

      expect(venue.bannerImagePosition?.focalPointX, 0.2);
      expect(venue.logoImagePosition?.scale, 1);
      expect(venue.galleryImagePositions['0']?.scale, 2.2);
    });
  });

  group('PositionedVenueImage', () {
    testWidgets('builds with metadata scale transform', (tester) async {
      const metadata = ImagePositionMetadata(focalPointX: 0, focalPointY: 1, scale: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 100,
              child: PositionedVenueImage(
                image: const ColoredBox(color: Colors.red),
                metadata: metadata,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PositionedVenueImage), findsOneWidget);
    });
  });
}
