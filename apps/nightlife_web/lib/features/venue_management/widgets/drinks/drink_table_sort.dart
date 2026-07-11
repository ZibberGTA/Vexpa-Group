import 'package:flutter/material.dart';
import 'package:vex_engines/experience/shared/experience_featured_sort.dart';

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
    return switch (column) {
      DrinkSortColumn.name => DrinkSortDirection.ascending,
      DrinkSortColumn.category => DrinkSortDirection.ascending,
      DrinkSortColumn.price => DrinkSortDirection.ascending,
      DrinkSortColumn.available => DrinkSortDirection.ascending,
      DrinkSortColumn.featured => DrinkSortDirection.ascending,
    };
  }
}

/// Applies search/filter sort within featured and non-featured groups.
/// Featured drinks always appear before non-featured drinks.
List<DrinkModel> sortDrinks(List<DrinkModel> drinks, DrinkTableSort sort) =>
    sortExperienceFeaturedFirst(
      drinks,
      (drink) => drink.featured,
      (a, b) => _compareDrinks(a, b, sort),
    );

int _compareDrinks(DrinkModel a, DrinkModel b, DrinkTableSort sort) {
  final comparison = switch (sort.column) {
    DrinkSortColumn.name =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    DrinkSortColumn.category => DrinkCategories.displayName(a.category)
        .toLowerCase()
        .compareTo(DrinkCategories.displayName(b.category).toLowerCase()),
    DrinkSortColumn.price => a.price.compareTo(b.price),
    DrinkSortColumn.available => _compareBool(
        a.available,
        b.available,
        trueFirst: true,
      ),
    DrinkSortColumn.featured => _compareBool(
        a.featured,
        b.featured,
        trueFirst: true,
      ),
  };

  if (comparison == 0) {
    final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (nameCompare == 0) return 0;
    return sort.direction == DrinkSortDirection.ascending
        ? nameCompare
        : -nameCompare;
  }

  return sort.direction == DrinkSortDirection.ascending
      ? comparison
      : -comparison;
}

int _compareBool(bool a, bool b, {required bool trueFirst}) {
  if (a == b) return 0;
  if (trueFirst) return a ? -1 : 1;
  return a ? 1 : -1;
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
