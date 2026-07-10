import 'package:test/test.dart';
import 'package:vex_engines/venue/shared/image_position_metadata.dart';

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
    });

    test('defaults to centred cover when map is empty', () {
      expect(
        ImagePositionMetadata.fromMap(null),
        ImagePositionMetadata.defaults,
      );
      expect(ImagePositionMetadata.fromMap({}).focalPointX, 0.5);
      expect(ImagePositionMetadata.fromMap({}).focalPointY, 0.5);
    });
  });

  group('ImageFrameKind', () {
    test('exposes aspect ratios and firestore keys', () {
      expect(ImageFrameKind.banner.aspectRatio, 2.85);
      expect(ImageFrameKind.logo.firestoreKey, 'logoImagePosition');
    });
  });
}
