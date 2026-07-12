import 'package:flutter/material.dart';
import 'package:vex_engines/experience/application/venue_content_ordering_service.dart';

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
    return DealSortDirection.ascending;
  }

  ExperienceDealTableSort toEngine() {
    return ExperienceDealTableSort(
      column: switch (column) {
        DealSortColumn.title => ExperienceDealSortColumn.title,
        DealSortColumn.dealType => ExperienceDealSortColumn.dealType,
        DealSortColumn.startDate => ExperienceDealSortColumn.startDate,
        DealSortColumn.endDate => ExperienceDealSortColumn.endDate,
        DealSortColumn.status => ExperienceDealSortColumn.status,
        DealSortColumn.featured => ExperienceDealSortColumn.featured,
      },
      direction: direction == DealSortDirection.ascending
          ? ExperienceSortDirection.ascending
          : ExperienceSortDirection.descending,
    );
  }
}

/// Featured deals always appear before non-featured deals.
List<DealModel> sortDeals(List<DealModel> deals, DealTableSort sort) {
  const ordering = VenueContentOrderingService();
  return ordering.sortDealsForTable(
    deals: deals,
    sort: sort.toEngine(),
    isFeatured: (deal) => deal.featured,
    title: (deal) => deal.title,
    dealTypeLabel: (deal) => DealTypes.displayName(deal.dealType),
    startDateTime: (deal) => deal.startDateTime,
    endDateTime: (deal) => deal.endDateTime,
    status: (deal) => computeDealStatus(deal),
  );
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
