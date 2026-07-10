import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/venue_dashboard_date_range.dart';

/// Dark glass date range selector for venue dashboard analytics.
class VenueDashboardDateRangeDropdown extends StatefulWidget {
  const VenueDashboardDateRangeDropdown({
    super.key,
    required this.selectedRange,
    required this.onChanged,
    this.options = VenueDashboardDateRange.values,
  });

  final VenueDashboardDateRange selectedRange;
  final ValueChanged<VenueDashboardDateRange> onChanged;
  final List<VenueDashboardDateRange> options;

  @override
  State<VenueDashboardDateRangeDropdown> createState() =>
      _VenueDashboardDateRangeDropdownState();
}

class _VenueDashboardDateRangeDropdownState
    extends State<VenueDashboardDateRangeDropdown> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = _focused || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: AppColors.surfaceElevated.withValues(alpha: 0.82),
          border: Border.all(
            color: highlighted
                ? AppColors.primaryPink.withValues(alpha: 0.75)
                : AppColors.primaryPurple.withValues(alpha: 0.22),
            width: highlighted ? 1.5 : 1,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<VenueDashboardDateRange>(
            value: widget.selectedRange,
            isDense: true,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            dropdownColor: AppColors.surfaceElevated,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: highlighted ? AppColors.primaryPink : AppColors.textSecondary,
            ),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
            onTap: () => setState(() => _focused = true),
            onChanged: (value) {
              setState(() => _focused = false);
              if (value != null) {
                widget.onChanged(value);
              }
            },
            items: widget.options
                .map(
                  (range) => DropdownMenuItem(
                    value: range,
                    child: Text(range.label),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
