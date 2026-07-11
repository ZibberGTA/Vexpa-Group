import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  group('DocumentAccessEvaluator', () {
    test('allows document owner access', () {
      final decision = DocumentAccessEvaluator.evaluate(
        identity: VexIdentity.fromProfile(
          uid: 'owner-1',
          dashboardRole: DashboardRole.venueOwner,
        ),
        metadata: const VexDocumentMetadata(
          path: 'claims/owner-1/evidence.pdf',
          ownerId: 'owner-1',
        ),
      );

      expect(decision.allowed, isTrue);
    });

    test('denies unrelated users', () {
      final decision = DocumentAccessEvaluator.evaluate(
        identity: VexIdentity.fromProfile(
          uid: 'user-1',
          dashboardRole: DashboardRole.regularUser,
        ),
        metadata: const VexDocumentMetadata(
          path: 'claims/owner-2/evidence.pdf',
          ownerId: 'owner-2',
        ),
      );

      expect(decision.allowed, isFalse);
    });
  });

  group('InMemoryConfigurationService', () {
    test('returns configured feature flags and values', () async {
      final config = InMemoryConfigurationService(
        featureFlags: {'privateDevelopmentMode': true},
        values: {'appName': 'Vexda'},
      );

      final flag = await config.featureFlag('privateDevelopmentMode');
      expect(flag.isEnabled, isTrue);
      expect(config.value('appName'), 'Vexda');
    });
  });
}
