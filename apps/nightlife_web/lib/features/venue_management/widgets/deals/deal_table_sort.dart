import 'package:flutter/material.dart';

import '../../../venue/data/models/deal_model.dart';
import '../../models/deal_status.dart';
import '../../models/deal_types.dart';

enum DealSortColumn {
  title,
  dealType,
  startDate,
  endDate,
  status,
  featured,
}

enum DealSortDirection {
  ascending,
  descending,
}

class DealTableSort {
  const DealTableSort({
    this.column = DealSortColumn.title,
    this.direction = DealSortDirection.ascending,
  });

  final DealSortColumn column;
  final DealSortDirection direction;

  DealTableSort toggleColumn(DealSortColumn column) {
    if (this.column == column) {
      return DealTableSort(
        column: column,
        direction: direction == DealSortDirection.ascending
            ? DealSortDirection.descending
            : DealSortDirection.ascending,
      );
    }

    return DealTableSort(
      column: column,
      direction: _defaultDirection(column),
    );
  }

  static DealSortDirection _defaultDirection(DealSortColumn column) {
    return switch (column) {
      DealSortColumn.title => DealSortDirection.ascending,
      DealSortColumn.dealType => DealSortDirection.ascending,
      DealSortColumn.startDate => DealSortDirection.ascending,
      DealSortColumn.endDate => DealSortDirection.ascending,
      DealSortColumn.status => DealSortDirection.ascending,
      DealSortColumn.featured => DealSortDirection.ascending,
    };
  }
}

/// Featured deals always appear before non-featured deals.
List<DealModel> sortDeals(List<DealModel> deals, DealTableSort sort) {
  final featured = <DealModel>[];
  final nonFeatured = <DealModel>[];

  for (final deal in deals) {
    if (deal.featured) {
      featured.add(deal);
    } else {
      nonFeatured.add(deal);
    }
  }

  return [
    ..._sortDealGroup(featured, sort),
    ..._sortDealGroup(nonFeatured, sort),
  ];
}

List<DealModel> _sortDealGroup(List<DealModel> deals, DealTableSort sort) {
  final sorted = List<DealModel>.from(deals);
  sorted.sort((a, b) => _compareDeals(a, b, sort));
  return sorted;
}

int _compareDeals(DealModel a, DealModel b, DealTableSort sort) {
  final comparison = switch (sort.column) {
    DealSortColumn.title =>
      a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    DealSortColumn.dealType => DealTypes.displayName(a.dealType)
        .toLowerCase()
        .compareTo(DealTypes.displayName(b.dealType).toLowerCase()),
    DealSortColumn.startDate => _compareDate(a.startDateTime, b.startDateTime),
    DealSortColumn.endDate => _compareDate(a.endDateTime, b.endDateTime),
    DealSortColumn.status => computeDealStatus(a)
        .label
        .compareTo(computeDealStatus(b).label),
    DealSortColumn.featured => _compareBool(a.featured, b.featured, trueFirst: true),
  };

  if (comparison == 0) {
    final titleCompare = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (titleCompare == 0) return 0;
    return sort.direction == DealSortDirection.ascending
        ? titleCompare
        : -titleCompare;
  }

  return sort.direction == DealSortDirection.ascending
      ? comparison
      : -comparison;
}

int _compareDate(DateTime? a, DateTime? b) {
  final aMillis = a?.millisecondsSinceEpoch ?? 0;
  final bMillis = b?.millisecondsSinceEpoch ?? 0;
  return aMillis.compareTo(bMillis);
}

int _compareBool(bool a, bool b, {required bool trueFirst}) {
  if (a == b) return 0;
  if (trueFirst) return a ? -1 : 1;
  return a ? 1 : -1;
}

String dealSortColumnLabel(DealSortColumn column) {
  return switch (column) {
    DealSortColumn.title => 'Deal Title',
    DealSortColumn.dealType => 'Deal Type',
    DealSortColumn.startDate => 'Start Date',
    DealSortColumn.endDate => 'End Date',
    DealSortColumn.status => 'Status',
    DealSortColumn.featured => 'Featured',
  };
}

Key dealSortColumnKey(DealSortColumn column) => Key('deal_sort_${column.name}');

Key dealSortIndicatorKey(DealSortColumn column) =>
    Key('deal_sort_indicator_${column.name}');

Key dealRowFeaturedBorderKey(String dealId) =>
    Key('deal_row_featured_border_$dealId');
