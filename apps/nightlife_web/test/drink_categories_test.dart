import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/venue_drinks_repository.dart';
import 'package:nightlife_web/features/venue_management/data/drink_write_payload.dart';
import 'package:nightlife_web/features/venue_management/models/drink_categories.dart';

void main() {
  group('DrinkCategories', () {
    test('includes all fixed categories without custom entries', () {
      expect(DrinkCategories.all, hasLength(21));
      expect(DrinkCategories.all, contains('Cocktails'));
      expect(DrinkCategories.all, contains('Other'));
      expect(DrinkCategories.all, isNot(contains('Custom Category')));
    });

    test('rejects custom categories', () {
      expect(DrinkCategories.isAllowed('Cocktails'), isTrue);
      expect(DrinkCategories.isAllowed('My Custom Category'), isFalse);
    });

    test('normalizes category for Firestore storage', () {
      expect(DrinkCategories.normalize('Sparkling Wine'), 'sparkling wine');
    });
  });

  group('AddDrinkFormValidator', () {
    test('requires drink name', () {
      expect(AddDrinkFormValidator.validateName(null), isNotNull);
      expect(AddDrinkFormValidator.validateName(''), isNotNull);
      expect(AddDrinkFormValidator.validateName('Espresso Martini'), isNull);
    });

    test('requires category from fixed list', () {
      expect(AddDrinkFormValidator.validateCategory(null), isNotNull);
      expect(AddDrinkFormValidator.validateCategory('Beer'), isNull);
      expect(AddDrinkFormValidator.validateCategory('Secret Menu'), isNotNull);
    });

    test('validates optional GBP price', () {
      expect(AddDrinkFormValidator.validatePrice(null), isNull);
      expect(AddDrinkFormValidator.validatePrice(''), isNull);
      expect(AddDrinkFormValidator.validatePrice('9.50'), isNull);
      expect(AddDrinkFormValidator.validatePrice('£12.00'), isNull);
      expect(AddDrinkFormValidator.validatePrice('abc'), isNotNull);
      expect(AddDrinkFormValidator.validatePrice('-1'), isNotNull);
    });
  });

  group('DrinkWritePayload', () {
    test('builds drinks collection payload with expected fields', () {
      final payload = DrinkWritePayload.build(
        venueId: 'venue-1',
        venueName: 'Copper Lantern',
        name: 'Espresso Martini',
        category: 'Cocktails',
        description: 'Classic coffee cocktail',
        available: true,
        featured: false,
        createdBy: 'owner-1',
        price: 9.5,
      );

      expect(payload['venueId'], 'venue-1');
      expect(payload['venueName'], 'Copper Lantern');
      expect(payload['name'], 'Espresso Martini');
      expect(payload['category'], 'cocktails');
      expect(payload['price'], 9.5);
      expect(payload['description'], 'Classic coffee cocktail');
      expect(payload['available'], isTrue);
      expect(payload['featured'], isFalse);
      expect(payload['isDeleted'], isFalse);
      expect(payload['createdBy'], 'owner-1');
      expect(payload['searchTerms'], isA<List<String>>());
      expect(payload['createdAt'], isNotNull);
      expect(payload['updatedAt'], isNotNull);
    });

    test('builds update payload without creating a new document shape', () {
      final payload = DrinkWritePayload.buildUpdate(
        venueName: 'Copper Lantern',
        name: 'Premium Lager',
        category: 'Beer',
        description: 'Crisp and refreshing',
        available: true,
        featured: false,
        updatedBy: 'owner-1',
        price: 6.5,
      );

      expect(payload.containsKey('venueId'), isFalse);
      expect(payload.containsKey('createdAt'), isFalse);
      expect(payload.containsKey('createdBy'), isFalse);
      expect(payload['name'], 'Premium Lager');
      expect(payload['category'], 'beer');
      expect(payload['updatedBy'], 'owner-1');
      expect(payload['updatedAt'], isNotNull);
    });
  });

  group('VenueDrinksRepository', () {
    test('rejects invalid categories before Firestore write', () async {
      final repository = VenueDrinksRepository(firestore: null);

      expect(
        () => repository.addDrink(
          venueId: 'venue-1',
          venueName: 'Test Venue',
          name: 'Mystery Drink',
          category: 'Custom Category',
          description: '',
          available: true,
          featured: false,
          createdBy: 'owner-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
