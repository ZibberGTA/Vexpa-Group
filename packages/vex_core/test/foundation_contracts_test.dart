import 'dart:io';

import 'package:test/test.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  group('VexCore package boundaries', () {
    test('lib sources do not import Firebase, Flutter, or vex_engines', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final forbidden = RegExp(
        r"import\s+'package:(firebase|cloud_firestore|flutter|vex_engines)/",
      );

      for (final file in libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final content = file.readAsStringSync();
        expect(
          forbidden.hasMatch(content),
          isFalse,
          reason: '${file.path} must stay provider- and engine-free',
        );
      }
    });
  });

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

  group('Legacy visibility parity', () {
    test('drink filter matches experience public visibility contract', () async {
      final repository = _LegacyDrinkRepository(
        drinks: [
          _drink(id: '1', name: 'Visible', available: true),
          _drink(id: '2', name: 'Unavailable', available: false),
          _drink(id: '3', name: 'Deleted', isDeleted: true),
        ],
      );
      final service = VenueDrinkDataService(repository: repository);

      final result = await service.loadPublicDrinks('venue-1');
      final drinks = (result as DataSuccess<List<VenueDrink>>).value;

      expect(drinks, hasLength(1));
      expect(drinks.first.name, 'Visible');
    });

    test('legacy deal visibility helpers remain backward compatible', () {
      final now = DateTime(2026, 1, 15, 20);
      final deal = VenueDeal(
        id: 'deal-1',
        venueId: 'venue-1',
        title: 'Happy Hour',
        description: '',
        dealType: 'percent',
        value: '10',
        startTime: '18:00',
        endTime: '22:00',
        isActive: true,
        featured: false,
        isDeleted: false,
        startDateTime: DateTime(2026, 1, 15, 18),
        endDateTime: DateTime(2026, 1, 15, 22),
      );

      expect(isPublicVisibleVenueDeal(deal, now: now), isTrue);
    });
  });
}

VenueDrink _drink({
  required String id,
  required String name,
  bool available = true,
  bool isDeleted = false,
}) {
  return VenueDrink(
    id: id,
    venueId: 'venue-1',
    name: name,
    category: 'Cocktails',
    price: 10,
    description: '',
    available: available,
    featured: false,
    isDeleted: isDeleted,
  );
}

final class _LegacyDrinkRepository implements VenueDrinkRepository {
  _LegacyDrinkRepository({required this.drinks});

  final List<VenueDrink> drinks;

  @override
  Future<DataResult<List<VenueDrink>>> loadPublicDrinks(String venueId) async {
    return DataSuccess(drinks);
  }

  @override
  Stream<DataResult<List<VenueDrink>>> watchPublicDrinks(String venueId) {
    return Stream.value(DataSuccess(drinks));
  }
}
