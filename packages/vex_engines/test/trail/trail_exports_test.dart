import 'dart:io';

import 'package:test/test.dart';
import 'package:vex_engines/trail/trail_engine.dart';
import 'package:vex_engines/vex_engines.dart';

void main() {
  test('trail engine exports compile', () {
    expect(trailEngineLibraryExists, isTrue);
    expect(TrailProgressService, isNotNull);
    expect(TrailVisibilityPolicy, isNotNull);
  });

  test('lib/trail sources do not import Firebase or Flutter', () {
    final dir = Directory('lib/trail');
    final forbidden = RegExp(
      r"import\s+'package:(firebase|cloud_firestore|flutter)/",
    );
    for (final file
        in dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      expect(forbidden.hasMatch(file.readAsStringSync()), isFalse);
    }
  });
}
