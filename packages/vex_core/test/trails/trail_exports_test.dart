import 'dart:io';

import 'package:test/test.dart';
import 'package:vex_core/trails/trails.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  group('Trail public exports', () {
    test('barrel exports repository contracts and snapshots', () {
      expect(TrailRepository, isNotNull);
      expect(TrailProgressRepository, isNotNull);
      expect(TrailActivityRepository, isNotNull);
      expect(TrailMediaRepository, isNotNull);
      expect(TrailSnapshot, isNotNull);
      expect(TrailPaths.trailsCollection, 'trails');
    });

    test('vex_core.dart exports trails barrel', () {
      expect(TrailListQuery, isNotNull);
      expect(CreateTrailCommand, isNotNull);
    });
  });

  group('Trail lib sources stay Firebase-free', () {
    test('lib/trails sources do not import Firebase or Flutter', () {
      final trailsDir = Directory('lib/trails');
      expect(trailsDir.existsSync(), isTrue);

      final forbidden = RegExp(
        r"import\s+'package:(firebase|cloud_firestore|flutter)/",
      );

      for (final file
          in trailsDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final content = file.readAsStringSync();
        expect(
          forbidden.hasMatch(content),
          isFalse,
          reason: '${file.path} must stay provider-free',
        );
      }
    });
  });
}
