import 'package:flutter/material.dart';

import 'package:vex_engines/experience/shared/experience_featured_sort.dart';

import '../../../../core/theme/app_spacing.dart';

/// Shared column identifiers for the events management table.
enum EventTableColumn {
  title,
  date,
  time,
  status,
  featured,
}

class EventTableLayout {
  EventTableLayout._();

  static const columns = EventTableColumn.values;

  static const titleFlex = 2;
  static const cellFlex = 1;

  static const checkboxWidth = 18.0;

  static int flexFor(EventTableColumn column) =>
      column == EventTableColumn.title ? titleFlex : cellFlex;

  static EdgeInsets headerPadding(EventTableColumn column) {
    return EdgeInsets.fromLTRB(
      column == EventTableColumn.title
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

  static String headerLabel(EventTableColumn column) => switch (column) {
        EventTableColumn.title => 'Event Title',
        EventTableColumn.date => 'Date',
        EventTableColumn.time => 'Time',
        EventTableColumn.status => 'Status',
        EventTableColumn.featured => 'Featured',
      };
}

/// Featured events always appear before non-featured events.
List<T> sortEventsFeaturedFirst<T>(
  List<T> items,
  bool Function(T item) isFeatured,
  int Function(T a, T b) compare,
) =>
    sortExperienceFeaturedFirst(items, isFeatured, compare);
