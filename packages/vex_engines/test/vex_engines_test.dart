import 'package:test/test.dart';
import 'package:vex_engines/vex_engines.dart';

void main() {
  test('vex_engines exports engine structure', () {
    expect(venueEngineLibraryExists, isTrue);
    expect(discoveryEngineLibraryExists, isTrue);
    expect(experienceEngineLibraryExists, isTrue);
    expect(claimEngineLibraryExists, isTrue);
  });
}
