import 'package:test/test.dart';
import 'package:vex_engines/vex_engines.dart';

void main() {
  test('vex_engines exports venue engine structure', () {
    expect(venueEngineLibraryExists, isTrue);
    expect(discoveryEngineLibraryExists, isTrue);
  });
}
