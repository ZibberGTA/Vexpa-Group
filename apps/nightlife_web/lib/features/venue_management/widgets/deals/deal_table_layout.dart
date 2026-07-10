import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'deal_table_sort.dart';

/// Shared column identifiers for the deals management table.
enum DealTableColumn {
  title,
  dealType,
  value,
  startDate,
  endDate,
  status,
  featured,
}

/// Shared flex and padding for deals table header and data rows.
class DealTableLayout {
  DealTableLayout._();

  static const columns = DealTableColumn.values;

  static const titleFlex = 2;
  static const cellFlex = 1;

  /// Width of the row selection checkbox including tap target.
  static const checkboxWidth = 18.0;

  static int flexFor(DealTableColumn column) =>
      column == DealTableColumn.title ? titleFlex : cellFlex;

  static EdgeInsets headerPadding(DealTableColumn column) {
    return EdgeInsets.fromLTRB(
      column == DealTableColumn.title
          ? AppSpacing.sm + checkboxWidth + AppSpacing.sm
          : AppSpacing.sm,
      AppSpacing.sm,
      AppSpacing.sm,
      AppSpacing.sm,
    );
  }

  static const cellPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.lg,
  );

  static String headerLabel(DealTableColumn column) => switch (column) {
        DealTableColumn.title => 'Deal Title',
        DealTableColumn.dealType => 'Deal Type',
        DealTableColumn.value => 'Value',
        DealTableColumn.startDate => 'Start Date',
        DealTableColumn.endDate => 'End Date',
        DealTableColumn.status => 'Status',
        DealTableColumn.featured => 'Featured',
      };

  static DealSortColumn? sortColumn(DealTableColumn column) => switch (column) {
        DealTableColumn.title => DealSortColumn.title,
        DealTableColumn.dealType => DealSortColumn.dealType,
        DealTableColumn.value => null,
        DealTableColumn.startDate => DealSortColumn.startDate,
        DealTableColumn.endDate => DealSortColumn.endDate,
        DealTableColumn.status => DealSortColumn.status,
        DealTableColumn.featured => DealSortColumn.featured,
      };
}
