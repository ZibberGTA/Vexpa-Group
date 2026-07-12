import 'package:flutter/material.dart';
import 'package:vex_engines/experience/application/venue_content_ordering_service.dart';

import '../../../venue/data/models/drink_model.dart';
import '../../models/drink_categories.dart';

enum DrinkSortColumn {
  name,
  category,
  price,
  available,
  featured,
}

enum DrinkSortDirection {
  ascending,
  descending,
}

class DrinkTableSort {
  const DrinkTableSort({
    this.column = DrinkSortColumn.name,
    this.direction = DrinkSortDirection.ascending,
  });

  final DrinkSortColumn column;
  final DrinkSortDirection direction;

  DrinkTableSort toggleColumn(DrinkSortColumn column) {
    if (this.column == column) {
      return DrinkTableSort(
        column: column,
        direction: direction == DrinkSortDirection.ascending
            ? DrinkSortDirection.descending
            : DrinkSortDirection.ascending,
      );
    }

    return DrinkTableSort(
      column: column,
      direction: _defaultDirection(column),
    );
  }

  static DrinkSortDirection _defaultDirection(DrinkSortColumn column) {
    return DrinkSortDirection.ascending;
  }

  ExperienceDrinkTableSort toEngine() {
    return ExperienceDrinkTableSort(
      column: switch (column) {
        DrinkSortColumn.name => ExperienceDrinkSortColumn.name,
        DrinkSortColumn.category => ExperienceDrinkSortColumn.category,
        DrinkSortColumn.price => ExperienceDrinkSortColumn.price,
        DrinkSortColumn.available => ExperienceDrinkSortColumn.available,
        DrinkSortColumn.featured => ExperienceDrinkSortColumn.featured,
      },
      direction: direction == DrinkSortDirection.ascending
          ? ExperienceSortDirection.ascending
          : ExperienceSortDirection.descending,
    );
  }
}

/// Applies search/filter sort within featured and non-featured groups.
/// Featured drinks always appear before non-featured drinks.
List<DrinkModel> sortDrinks(List<DrinkModel> drinks, DrinkTableSort sort) {
  const ordering = VenueContentOrderingService();
  return ordering.sortDrinksForTable(
    drinks: drinks,
    sort: sort.toEngine(),
    isFeatured: (drink) => drink.featured,
    name: (drink) => drink.name,
    categoryLabel: (drink) => DrinkCategories.displayName(drink.category),
    price: (drink) => drink.price,
    available: (drink) => drink.available,
  );
}

String drinkSortColumnLabel(DrinkSortColumn column) {
  return switch (column) {
    DrinkSortColumn.name => 'Name',
    DrinkSortColumn.category => 'Category',
    DrinkSortColumn.price => 'Price',
    DrinkSortColumn.available => 'Available',
    DrinkSortColumn.featured => 'Featured',
  };
}

Key drinkSortColumnKey(DrinkSortColumn column) =>
    Key('drink_sort_${column.name}');

Key drinkSortIndicatorKey(DrinkSortColumn column) =>
    Key('drink_sort_indicator_${column.name}');

Key drinkRowFeaturedBorderKey(String drinkId) =>
    Key('drink_row_featured_border_$drinkId');
