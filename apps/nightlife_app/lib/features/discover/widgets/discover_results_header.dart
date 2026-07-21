import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/discover_models.dart';

class DiscoverResultsHeader extends StatelessWidget {
  const DiscoverResultsHeader({
    super.key,
    required this.filter,
    required this.resultCount,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final DiscoverFilter filter;
  final int resultCount;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = resultCount > 0
        ? '$resultCount ${filter.resultsHeaderTitle.toLowerCase()}'
        : filter.resultsHeaderTitle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                filter.resultsHeaderSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onToggleExpanded,
          icon: Icon(
            expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            color: AppColors.textSecondary,
          ),
          tooltip: expanded ? 'Collapse results' : 'Expand results',
        ),
      ],
    );
  }
}
