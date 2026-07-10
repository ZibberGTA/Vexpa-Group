import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  test('exports shared result primitives', () {
    const result = VexSuccess('ok');

    expect(result.value, 'ok');
  });
}
