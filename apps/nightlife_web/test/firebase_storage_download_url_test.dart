import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/firebase/firebase_storage_download_url.dart';

void main() {
  group('parseFirebaseStoragePathFromDownloadUrl', () {
    test('parses googleapis Firebase Storage download URL', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/nightlife-app-19acd.firebasestorage.app/o/venues%2FMVNhJuaLj5lpHGch9SPK%2Fmedia%2Flogo%2F1782979758438000.jpg?alt=media&token=abc';

      expect(
        parseFirebaseStoragePathFromDownloadUrl(url),
        'venues/MVNhJuaLj5lpHGch9SPK/media/logo/1782979758438000.jpg',
      );
    });

    test('parses firebasestorage.app download URL', () {
      const url =
          'https://nightlife-app-19acd.firebasestorage.app/o/venues%2Fvenue%2Fmedia%2Fbanner.jpg?alt=media&token=abc';

      expect(
        parseFirebaseStoragePathFromDownloadUrl(url),
        'venues/venue/media/banner.jpg',
      );
    });

    test('returns null for non-Firebase URLs', () {
      expect(
        parseFirebaseStoragePathFromDownloadUrl('https://example.com/logo.png'),
        isNull,
      );
    });
  });
}
