import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../../venue/data/models/deal_model.dart';
import '../../../venue/data/venue_deals_repository.dart';
import '../../models/bulk_deal_patch.dart';
import '../../models/deal_status.dart';
import '../../models/deal_types.dart';
import '../../models/featured_deals_limit.dart';
import '../drinks/drink_selection_checkbox.dart';
import '../inline_edit/inline_editable_date_cell.dart';
import '../inline_edit/inline_editable_dropdown_cell.dart';
import '../inline_edit/inline_editable_text_cell.dart';
import '../inline_edit/inline_editable_toggle_cell.dart';
import '../inline_edit/inline_edit_cell_theme.dart';
import 'deal_table_layout.dart';
import 'deal_table_sort.dart';

/// Deal row with inline-editable table cells.
class DealRow extends StatefulWidget {
  const DealRow({
    super.key,
    required this.deal,
    required this.repository,
    required this.venueName,
    required this.venueDeals,
    required this.updatedBy,
    required this.isSelected,
    required this.onSelectionChanged,
    this.onAdvancedEdit,
    this.showDivider = true,
  });

  final DealModel deal;
  final VenueDealsRepository repository;
  final String venueName;
  final List<DealModel> venueDeals;
  final String? updatedBy;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback? onAdvancedEdit;
  final bool showDivider;

  @override
  State<DealRow> createState() => _DealRowState();
}

class _DealRowState extends State<DealRow> {
  bool _hovered = false;

  Future<String?> _patch(BulkDealPatch patch) async {
    final userId = widget.updatedBy;
    if (userId == null) return 'You must be signed in to edit deals.';

    try {
      await widget.repository.patchDeal(
        dealId: widget.deal.id,
        venueName: widget.venueName,
        title: widget.deal.title,
        description: widget.deal.description,
        dealType: widget.deal.dealType,
        value: widget.deal.value,
        patch: patch,
        updatedBy: userId,
      );
      return null;
    } catch (_) {
      return 'Could not save. Please try again.';
    }
  }

  DateTime _mergeDate(DateTime? existing, DateTime picked) {
    if (existing == null) return picked;
    return DateTime(
      picked.year,
      picked.month,
      picked.day,
      existing.hour,
      existing.minute,
    );
  }

  Widget _buildCell(DealTableColumn column, DealStatus status) {
    final deal = widget.deal;

    switch (column) {
      case DealTableColumn.title:
        return Row(
          children: [
            DrinkSelectionCheckbox(
              key: Key('deal_select_${deal.id}'),
              value: widget.isSelected,
              semanticLabel: 'Select ${deal.title}',
              onChanged: widget.onSelectionChanged,
            ),
            Expanded(
              child: InlineEditableTextCell(
                value: deal.title,
                displayStyle: InlineEditCellTheme.titleDisplayTextStyle
                    .copyWith(letterSpacing: deal.featured ? 0.15 : 0),
                hintText: 'Deal title',
                onAdvancedEdit: widget.onAdvancedEdit,
                validate: AddDealFormValidator.validateTitle,
                onSave: (value) => _patch(BulkDealPatch(title: value)),
              ),
            ),
          ],
        );
      case DealTableColumn.dealType:
        return InlineEditableDropdownCell<String>(
          value: deal.dealType,
          items: DealTypes.all,
          displayLabel: DealTypes.displayName,
          validate: (value) => AddDealFormValidator.validateDealType(value),
          onSave: (value) => _patch(BulkDealPatch(dealType: value)),
        );
      case DealTableColumn.value:
        return InlineEditableTextCell(
          value: deal.value,
          hintText: 'Value',
          validate: AddDealFormValidator.validateValue,
          onSave: (value) => _patch(BulkDealPatch(value: value)),
        );
      case DealTableColumn.startDate:
        return InlineEditableDateCell(
          value: deal.startDateTime,
          displayText: deal.formattedStartDate,
          onSave: (date) => _patch(
            BulkDealPatch(
              startDateTime: _mergeDate(deal.startDateTime, date),
            ),
          ),
        );
      case DealTableColumn.endDate:
        return InlineEditableDateCell(
          value: deal.endDateTime,
          displayText: deal.formattedEndDate,
          firstDate: deal.startDateTime,
          onSave: (date) {
            final merged = _mergeDate(deal.endDateTime, date);
            if (deal.startDateTime != null && !merged.isAfter(deal.startDateTime!)) {
              return Future.value('End date must be after start date.');
            }
            return _patch(BulkDealPatch(endDateTime: merged));
          },
        );
      case DealTableColumn.status:
        return _DealStatusToggleCell(
          status: status,
          isActive: deal.isActive,
          onSave: (value) => _patch(BulkDealPatch(isActive: value)),
        );
      case DealTableColumn.featured:
        return InlineEditableToggleCell(
          value: deal.featured,
          onSave: (value) {
            final limitError = FeaturedDealsLimit.validateEdit(
              deal: deal,
              wantsFeatured: value,
              venueDeals: widget.venueDeals,
            );
            if (limitError != null) return Future.value(limitError);
            return _patch(BulkDealPatch(featured: value));
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final status = computeDealStatus(deal);
    final highlighted = widget.isSelected || _hovered;

    final rowContent = AnimatedContainer(
      duration: PremiumEffects.fast,
      curve: PremiumEffects.easeOut,
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryPurple.withValues(alpha: 0.14)
            : deal.featured
                ? AppColors.surfaceElevated.withValues(alpha: 0.72)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: highlighted && !deal.featured
            ? PremiumEffects.hoverGlow(intensity: 0.35)
            : null,
      ),
      child: Row(
        children: [
          for (final column in DealTableLayout.columns)
            Expanded(
              flex: DealTableLayout.flexFor(column),
              child: Padding(
                padding: DealTableLayout.cellPadding,
                child: _buildCell(column, status),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: deal.featured
              ? Padding(
                  key: dealRowFeaturedBorderKey(deal.id),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 1),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.trailGold.withValues(alpha: 0.5),
                          AppColors.primaryPink.withValues(alpha: 0.32),
                          AppColors.primaryPurple.withValues(alpha: 0.5),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.trailGold.withValues(alpha: 0.08),
                          blurRadius: 12,
                          spreadRadius: -4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        child: rowContent,
                      ),
                    ),
                  ),
                )
              : rowContent,
        ),
        if (widget.showDivider)
          Divider(
            height: 1,
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

/// Status badge that toggles active/paused on click.
class _DealStatusToggleCell extends StatefulWidget {
  const _DealStatusToggleCell({
    required this.status,
    required this.isActive,
    required this.onSave,
  });

  final DealStatus status;
  final bool isActive;
  final Future<String?> Function(bool value) onSave;

  @override
  State<_DealStatusToggleCell> createState() => _DealStatusToggleCellState();
}

class _DealStatusToggleCellState extends State<_DealStatusToggleCell> {
  InlineCellSaveState _saveState = InlineCellSaveState.idle;
  String? _errorMessage;

  Future<void> _toggle() async {
    if (_saveState == InlineCellSaveState.saving) return;

    setState(() {
      _saveState = InlineCellSaveState.saving;
      _errorMessage = null;
    });

    try {
      final error = await widget.onSave(!widget.isActive);
      if (!mounted) return;

      if (error != null) {
        setState(() {
          _saveState = InlineCellSaveState.error;
          _errorMessage = error;
        });
        return;
      }

      setState(() => _saveState = InlineCellSaveState.success);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _saveState = InlineCellSaveState.idle);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveState = InlineCellSaveState.error;
        _errorMessage = 'Could not save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: DealStatusBadge(status: widget.status),
          ),
        ),
        InlineEditFeedback(
          state: _saveState,
          errorMessage: _errorMessage,
        ),
      ],
    );
  }
}

/// Status badge for deal management rows.
class DealStatusBadge extends StatelessWidget {
  const DealStatusBadge({super.key, required this.status});

  final DealStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      DealStatus.active => (
          AppColors.primaryPink.withValues(alpha: 0.18),
          AppColors.primaryPink.withValues(alpha: 0.85),
        ),
      DealStatus.scheduled => (
          AppColors.primaryPurple.withValues(alpha: 0.22),
          AppColors.primaryPurple.withValues(alpha: 0.95),
        ),
      DealStatus.expired => (
          AppColors.textSecondary.withValues(alpha: 0.14),
          AppColors.textSecondary.withValues(alpha: 0.85),
        ),
      DealStatus.paused => (
          AppColors.trailGold.withValues(alpha: 0.16),
          AppColors.trailGold.withValues(alpha: 0.92),
        ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: colors.$2.withValues(alpha: 0.35)),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: colors.$2,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

/// Column headers for the deals management table.
class DealTableHeader extends StatelessWidget {
  const DealTableHeader({
    super.key,
    required this.sort,
    required this.onSortColumn,
  });

  final DealTableSort sort;
  final ValueChanged<DealSortColumn> onSortColumn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final column in DealTableLayout.columns)
              Expanded(
                flex: DealTableLayout.flexFor(column),
                child: _buildHeaderCell(column),
              ),
          ],
        ),
        Divider(
          height: 1,
          color: AppColors.primaryPurple.withValues(alpha: 0.08),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(DealTableColumn column) {
    final sortColumn = DealTableLayout.sortColumn(column);
    final padding = DealTableLayout.headerPadding(column);

    if (sortColumn == null) {
      return Padding(
        padding: padding,
        child: Text(
          DealTableLayout.headerLabel(column),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

    return _SortableHeaderCell(
      label: DealTableLayout.headerLabel(column),
      column: sortColumn,
      sort: sort,
      onSortColumn: onSortColumn,
      padding: padding,
    );
  }
}

class _SortableHeaderCell extends StatefulWidget {
  const _SortableHeaderCell({
    required this.label,
    required this.column,
    required this.sort,
    required this.onSortColumn,
    required this.padding,
  });

  final String label;
  final DealSortColumn column;
  final DealTableSort sort;
  final ValueChanged<DealSortColumn> onSortColumn;
  final EdgeInsets padding;

  @override
  State<_SortableHeaderCell> createState() => _SortableHeaderCellState();
}

class _SortableHeaderCellState extends State<_SortableHeaderCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.sort.column == widget.column;
    final indicator = isActive
        ? (widget.sort.direction == DealSortDirection.ascending
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded)
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: dealSortColumnKey(widget.column),
        onTap: () => widget.onSortColumn(widget.column),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: widget.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: isActive || _hovered
                        ? AppColors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (indicator != null) ...[
                const SizedBox(width: 2),
                Icon(
                  key: dealSortIndicatorKey(widget.column),
                  indicator,
                  size: 14,
                  color: AppColors.primaryPink.withValues(alpha: 0.9),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
