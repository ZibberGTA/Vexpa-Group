import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/firebase_venue_drink_repository.dart';
import 'package:nightlife_web/features/venue/data/models/drink_model.dart';
import 'package:nightlife_web/features/venue/data/venue_drinks_grouper.dart';
import 'package:nightlife_web/features/venue/data/venue_drinks_repository.dart';
import 'package:vex_core/vex_core.dart';

import 'support/mock_venue_drink_repository.dart';

void main() {
  group('FirebaseVenueDrinkRepository public drink mapping', () {
    test('maps valid drink documents', () {
      final drink = FirebaseVenueDrinkRepository.mapDrinkEntry('drink-1', {
        'venueId': 'venue-1',
        'name': 'Negroni',
        'category': 'cocktails',
        'price': 12.5,
        'description': 'Classic pour',
        'available': true,
        'featured': true,
        'isDeleted': false,
      });

      expect(drink, isNotNull);
      expect(drink!.id, 'drink-1');
      expect(drink.name, 'Negroni');
      expect(drink.price, 12.5);
      expect(drink.featured, isTrue);
    });

    test('deleted drink is excluded', () {
      final drink = FirebaseVenueDrinkRepository.mapDrinkEntry('drink-1', {
        'venueId': 'venue-1',
        'name': 'Old Fashioned',
        'category': 'cocktails',
        'isDeleted': true,
      });

      expect(drink, isNull);
    });

    test('draft drink is excluded', () {
      final drink = FirebaseVenueDrinkRepository.mapDrinkEntry('drink-1', {
        'venueId': 'venue-1',
        'name': 'Draft Pour',
        'category': 'cocktails',
        'status': 'draft',
      });

      expect(drink, isNull);
    });

    test('hidden drink is excluded', () {
      final drink = FirebaseVenueDrinkRepository.mapDrinkEntry('drink-1', {
        'venueId': 'venue-1',
        'name': 'Hidden Pour',
        'category': 'cocktails',
        'isHidden': true,
      });

      expect(drink, isNull);
    });

    test('inactive drink is excluded', () {
      final drink = FirebaseVenueDrinkRepository.mapDrinkEntry('drink-1', {
        'venueId': 'venue-1',
        'name': 'Inactive Pour',
        'category': 'cocktails',
        'status': 'inactive',
      });

      expect(drink, isNull);
    });

    test('malformed drink is denied safely', () {
      expect(
        FirebaseVenueDrinkRepository.mapDrinkEntry('drink-1', null),
        isNull,
      );
    });

    test('preserves category grouping and ordering behaviour', () {
      final drinks =
          FirebaseVenueDrinkRepository.mapDrinkData([
                MapEntry('1', {
                  'venueId': 'venue-1',
                  'name': 'Zeta Beer',
                  'category': 'beer',
                  'available': false,
                }),
                MapEntry('2', {
                  'venueId': 'venue-1',
                  'name': 'Alpha Cocktail',
                  'category': 'cocktails',
                  'available': true,
                }),
                MapEntry('3', {
                  'venueId': 'venue-1',
                  'name': 'Beta Cocktail',
                  'category': 'cocktails',
                  'available': true,
                }),
              ])
              .map(
                (drink) => DrinkModel(
                  id: drink.id,
                  venueId: drink.venueId,
                  name: drink.name,
                  category: drink.category,
                  price: drink.price,
                  description: drink.description,
                  available: drink.available,
                  featured: drink.featured,
                  isDeleted: drink.isDeleted,
                ),
              )
              .toList();

      final grouped = VenueDrinksGrouper.groupByCategory(drinks);

      expect(grouped.keys.first, 'Cocktails');
      expect(grouped['Cocktails']!.map((drink) => drink.name), [
        'Alpha Cocktail',
        'Beta Cocktail',
      ]);
      expect(grouped['Beers']!.single.name, 'Zeta Beer');
    });
  });

  group('VenueDrinksRepository via VexCore', () {
    test('watchDrinks streams drinks through VenueDrinkDataService', () async {
      final controller = StreamController<DataResult<List<VenueDrink>>>();
      final repository = VenueDrinksRepository(
        venueDrinkDataService: VenueDrinkDataService(
          repository: MockVenueDrinkRepository(watchStream: controller.stream),
        ),
      );

      final results = <List<DrinkModel>>[];
      final subscription = repository
          .watchDrinks('venue-1')
          .listen(results.add);

      controller.add(
        DataSuccess([
          mockVenueDrink(id: '1', name: 'Alpha'),
          mockVenueDrink(id: '2', name: 'Beta'),
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();
      await controller.close();

      expect(results.single.map((drink) => drink.name), ['Alpha', 'Beta']);
    });

    test('returns empty list for blank venue ID', () async {
      final repository = VenueDrinksRepository(
        venueDrinkDataService: VenueDrinkDataService(
          repository: MockVenueDrinkRepository(),
        ),
      );

      expect(await repository.watchDrinks('  ').first, isEmpty);
    });

    test('rethrows repository failures for error state parity', () async {
      final repository = VenueDrinksRepository(
        venueDrinkDataService: VenueDrinkDataService(
          repository: MockVenueDrinkRepository(
            watchStream: Stream.value(
              DataFailure(
                const VexException('denied', code: 'permission-denied'),
              ),
            ),
          ),
        ),
      );

      expect(
        () => repository.watchDrinks('venue-1').first,
        throwsA(isA<VexException>()),
      );
    });

    test('watchDrinks excludes unavailable drinks through public pipeline', () async {
      final repository = VenueDrinksRepository(
        venueDrinkDataService: VenueDrinkDataService(
          repository: MockVenueDrinkRepository(
            publicDrinks: [
              mockVenueDrink(id: '1', name: 'Visible'),
              mockVenueDrink(id: '2', name: 'Hidden', available: false),
            ],
          ),
        ),
      );

      final drinks = await repository.watchDrinks('venue-1').first;

      expect(drinks.map((drink) => drink.name), ['Visible']);
    });
  });
}
