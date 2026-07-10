import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/models/drink_model.dart';
import 'package:nightlife_web/features/venue_management/models/featured_drinks_limit.dart';
import 'package:nightlife_web/features/venue_management/widgets/drinks/drink_table_sort.dart';

DrinkModel _drink({
  required String id,
  required String name,
  required String category,
  double price = 0,
  bool available = true,
  bool featured = false,
}) {
  return DrinkModel(
    id: id,
    venueId: 'venue-test',
    name: name,
    category: category,
    price: price,
    description: '',
    available: available,
    featured: featured,
    isDeleted: false,
  );
}

void main() {
  group('FeaturedDrinksLimit', () {
    test('validateAdd blocks when venue already has max featured drinks', () {
      final drinks = List.generate(
        FeaturedDrinksLimit.maxFeaturedDrinks,
        (index) => _drink(
          id: 'featured-$index',
          name: 'Drink $index',
          category: 'Beer',
          featured: true,
        ),
      );

      expect(
        FeaturedDrinksLimit.validateAdd(
          wantsFeatured: true,
          venueDrinks: drinks,
        ),
        FeaturedDrinksLimit.limitMessage,
      );
      expect(
        FeaturedDrinksLimit.validateAdd(
          wantsFeatured: false,
          venueDrinks: drinks,
        ),
        isNull,
      );
    });

    test('validateEdit allows keeping an existing featured drink', () {
      final drinks = List.generate(
        FeaturedDrinksLimit.maxFeaturedDrinks,
        (index) => _drink(
          id: 'featured-$index',
          name: 'Drink $index',
          category: 'Beer',
          featured: true,
        ),
      );

      expect(
        FeaturedDrinksLimit.validateEdit(
          drink: drinks.first,
          wantsFeatured: true,
          venueDrinks: drinks,
        ),
        isNull,
      );
    });

    test('validateEdit blocks enabling featured when limit reached', () {
      final drinks = List.generate(
        FeaturedDrinksLimit.maxFeaturedDrinks,
        (index) => _drink(
          id: 'featured-$index',
          name: 'Drink $index',
          category: 'Beer',
          featured: true,
        ),
      );
      final nonFeatured = _drink(
        id: 'regular',
        name: 'Regular Lager',
        category: 'Beer',
      );

      expect(
        FeaturedDrinksLimit.validateEdit(
          drink: nonFeatured,
          wantsFeatured: true,
          venueDrinks: [...drinks, nonFeatured],
        ),
        FeaturedDrinksLimit.limitMessage,
      );
    });

    test('validateBulkEdit blocks too many featured drinks across venue', () {
      final venueDrinks = [
        ...List.generate(
          4,
          (index) => _drink(
            id: 'featured-$index',
            name: 'Featured $index',
            category: 'Beer',
            featured: true,
          ),
        ),
        _drink(id: 'a', name: 'Drink A', category: 'Beer'),
        _drink(id: 'b', name: 'Drink B', category: 'Beer'),
      ];
      final selected = venueDrinks.where((drink) => drink.id == 'a' || drink.id == 'b').toList();

      expect(
        FeaturedDrinksLimit.validateBulkEdit(
          selectedDrinks: selected,
          venueDrinks: venueDrinks,
          proposedFeaturedValues: const [true, true],
        ),
        FeaturedDrinksLimit.limitMessage,
      );
    });
  });

  group('sortDrinks', () {
    final drinks = [
      _drink(id: '1', name: 'Zulu Ale', category: 'beer', price: 8, available: false, featured: false),
      _drink(id: '2', name: 'Alpha Gin', category: 'gin', price: 4, available: true, featured: true),
      _drink(id: '3', name: 'Mid Lager', category: 'cocktails', price: 6, available: true, featured: false),
    ];

    test('defaults to drink name A to Z with featured drinks first', () {
      final sorted = sortDrinks(drinks, const DrinkTableSort());
      expect(sorted.map((drink) => drink.name), ['Alpha Gin', 'Mid Lager', 'Zulu Ale']);
    });

    test('featured drinks always appear before non-featured drinks', () {
      final sorted = sortDrinks(
        drinks,
        const DrinkTableSort(column: DrinkSortColumn.category, direction: DrinkSortDirection.descending),
      );
      expect(sorted.first.featured, isTrue);
      expect(sorted.first.name, 'Alpha Gin');
      expect(sorted.skip(1).every((drink) => !drink.featured), isTrue);
    });

    test('category ascending then descending within groups', () {
      final ascending = sortDrinks(
        drinks,
        const DrinkTableSort(column: DrinkSortColumn.category, direction: DrinkSortDirection.ascending),
      );
      expect(ascending.map((drink) => drink.name), ['Alpha Gin', 'Zulu Ale', 'Mid Lager']);

      final descending = sortDrinks(
        drinks,
        const DrinkTableSort(column: DrinkSortColumn.category, direction: DrinkSortDirection.descending),
      );
      expect(descending.map((drink) => drink.name), ['Alpha Gin', 'Mid Lager', 'Zulu Ale']);
    });

    test('price ascending then descending within groups', () {
      final ascending = sortDrinks(
        drinks,
        const DrinkTableSort(column: DrinkSortColumn.price, direction: DrinkSortDirection.ascending),
      );
      expect(ascending.map((drink) => drink.name), ['Alpha Gin', 'Mid Lager', 'Zulu Ale']);

      final descending = sortDrinks(
        drinks,
        const DrinkTableSort(column: DrinkSortColumn.price, direction: DrinkSortDirection.descending),
      );
      expect(descending.map((drink) => drink.name), ['Alpha Gin', 'Zulu Ale', 'Mid Lager']);
    });

    test('available ascending puts available drinks first within groups', () {
      final ascending = sortDrinks(
        drinks,
        const DrinkTableSort(column: DrinkSortColumn.available, direction: DrinkSortDirection.ascending),
      );
      expect(ascending.map((drink) => drink.name), ['Alpha Gin', 'Mid Lager', 'Zulu Ale']);

      final descending = sortDrinks(
        drinks,
        const DrinkTableSort(column: DrinkSortColumn.available, direction: DrinkSortDirection.descending),
      );
      expect(descending.map((drink) => drink.name), ['Alpha Gin', 'Zulu Ale', 'Mid Lager']);
    });

    test('featured column toggles order within each group', () {
      final ascending = sortDrinks(
        drinks,
        const DrinkTableSort(column: DrinkSortColumn.featured, direction: DrinkSortDirection.ascending),
      );
      expect(ascending.map((drink) => drink.name), ['Alpha Gin', 'Mid Lager', 'Zulu Ale']);

      final descending = sortDrinks(
        drinks,
        const DrinkTableSort(column: DrinkSortColumn.featured, direction: DrinkSortDirection.descending),
      );
      expect(descending.map((drink) => drink.name), ['Alpha Gin', 'Zulu Ale', 'Mid Lager']);
    });
  });

  group('DrinkTableSort.toggleColumn', () {
    test('toggles direction on same column and resets on new column', () {
      const initial = DrinkTableSort();
      final toggled = initial.toggleColumn(DrinkSortColumn.name);
      expect(toggled.direction, DrinkSortDirection.descending);

      final priceSort = toggled.toggleColumn(DrinkSortColumn.price);
      expect(priceSort.column, DrinkSortColumn.price);
      expect(priceSort.direction, DrinkSortDirection.ascending);
    });
  });
}
