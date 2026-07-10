import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Column sort state for admin CRM tables.
class AdminCrmTableSort {
  const AdminCrmTableSort({required this.column, required this.ascending});

  final String column;
  final bool ascending;

  AdminCrmTableSort toggleColumn(String columnKey) {
    if (column == columnKey) {
      return AdminCrmTableSort(column: columnKey, ascending: !ascending);
    }
    return AdminCrmTableSort(column: columnKey, ascending: true);
  }
}

/// Premium clickable column header with sort direction indicator.
class AdminCrmSortableHeader extends StatefulWidget {
  const AdminCrmSortableHeader({
    super.key,
    required this.label,
    required this.columnKey,
    required this.activeColumnKey,
    required this.ascending,
    required this.onSort,
  });

  final String label;
  final String columnKey;
  final String activeColumnKey;
  final bool ascending;
  final ValueChanged<String> onSort;

  @override
  State<AdminCrmSortableHeader> createState() => _AdminCrmSortableHeaderState();
}

class _AdminCrmSortableHeaderState extends State<AdminCrmSortableHeader> {
  bool _hovering = false;

  bool get _isActive => widget.activeColumnKey == widget.columnKey;

  @override
  Widget build(BuildContext context) {
    final icon = _isActive
        ? (widget.ascending
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded)
        : Icons.unfold_more_rounded;

    final iconColor = _isActive
        ? AppColors.primaryPink.withValues(alpha: 0.95)
        : AppColors.textSecondary.withValues(alpha: _hovering ? 0.85 : 0.55);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => widget.onSort(widget.columnKey),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          hoverColor: AppColors.primaryPurple.withValues(alpha: 0.14),
          splashColor: AppColors.primaryPurple.withValues(alpha: 0.18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: _isActive
                  ? AppColors.primaryPurple.withValues(alpha: 0.12)
                  : _hovering
                  ? AppColors.primaryPurple.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: _isActive
                    ? AppColors.primaryPurple.withValues(alpha: 0.28)
                    : _hovering
                    ? AppColors.primaryPurple.withValues(alpha: 0.16)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: _isActive
                          ? AppColors.white
                          : AppColors.textSecondary.withValues(
                              alpha: _hovering ? 0.98 : 0.88,
                            ),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 14, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

DataColumn adminCrmSortableDataColumn({
  required String label,
  required String columnKey,
  required String activeColumnKey,
  required bool ascending,
  required ValueChanged<String> onSort,
}) {
  return DataColumn(
    label: AdminCrmSortableHeader(
      label: label,
      columnKey: columnKey,
      activeColumnKey: activeColumnKey,
      ascending: ascending,
      onSort: onSort,
    ),
  );
}
