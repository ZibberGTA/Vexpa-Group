import 'package:test/test.dart';
import 'package:vex_engines/venue/shared/crowd_status_presentation.dart';

void main() {
  group('CrowdStatusPresentation', () {
    test('labelForLevel maps internal levels to customer wording', () {
      expect(CrowdStatusPresentation.labelForLevel('quiet'), 'Relaxed');
      expect(CrowdStatusPresentation.labelForLevel('packed'), 'Lively');
      expect(CrowdStatusPresentation.labelForLevel('busy'), 'Buzzing');
    });

    test('displayLabel applies decay before labelling', () {
      final updatedAt = DateTime.now().subtract(const Duration(hours: 8));

      expect(
        CrowdStatusPresentation.displayLabel(
          level: 'packed',
          updatedAt: updatedAt,
        ),
        'Relaxed',
      );
    });
  });
}
