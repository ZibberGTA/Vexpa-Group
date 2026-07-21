import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../../venue/data/models/drink_model.dart';
import '../../../venue/data/venue_drinks_repository.dart';
import '../../data/venue_management_page_activity_support.dart';
import '../../models/bulk_drink_patch.dart';
import '../../models/drink_categories.dart';
import '../../models/featured_drinks_limit.dart';
import '../inline_edit/inline_editable_dropdown_cell.dart';
import '../inline_edit/inline_editable_price_cell.dart';
import '../inline_edit/inline_editable_text_cell.dart';
import '../inline_edit/inline_editable_toggle_cell.dart';
import '../inline_edit/inline_edit_cell_theme.dart';
import 'drink_selection_checkbox.dart';
import 'drink_table_sort.dart';

/// Drink row with inline-editable table cells.
class DrinkRow extends StatefulWidget {
  const DrinkRow({
    super.key,
    required this.drink,
    required this.repository,
    required this.venueName,
    required this.venueDrinks,
    required this.updatedBy,
    required this.isSelected,
    required this.onSelectionChanged,
    this.onAdvancedEdit,
    this.showDivider = true,
  });

  final DrinkModel drink;
  final VenueDrinksRepository repository;
  final String venueName;
  final List<DrinkModel> venueDrinks;
  final String? updatedBy;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback? onAdvancedEdit;
  final bool showDivider;

  @override
  State<DrinkRow> createState() => _DrinkRowState();
}

class _DrinkRowState extends State<DrinkRow> {
  bool _hovered = false;

  Future<String?> _patch(BulkDrinkPatch patch) async {
    final userId = widget.updatedBy;
    if (userId == null) return 'You must be signed in to edit drinks.';

    try {
      await widget.repository.patchDrink(
        drinkId: widget.drink.id,
        venueId: widget.drink.venueId,
        venueName: widget.venueName,
        drinkName: widget.drink.name,
        category: widget.drink.category,
        patch: patch,
        updatedBy: userId,
      );
      if (!context.mounted) return null;
      await reloadVenueManagementPageActivity(context);
      return null;
    } catch (_) {
      return 'Could not save. Please try again.';
    }
  }

  String? _validateFeatured(bool wantsFeatured) {
    return FeaturedDrinksLimit.validateEdit(
      drink: widget.drink,
      wantsFeatured: wantsFeatured,
      venueDrinks: widget.venueDrinks,
    );
  }

  String _categoryDisplay() {
    var category = DrinkCategories.displayName(widget.drink.category);
    if (!DrinkCategories.isAllowed(category)) category = 'Other';
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final drink = widget.drink;
    final highlighted = widget.isSelected || _hovered;

    final rowContent = AnimatedContainer(
      duration: PremiumEffects.fast,
      curve: PremiumEffects.easeOut,
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryPurple.withValues(alpha: 0.14)
            : drink.featured
                ? AppColors.surfaceElevated.withValues(alpha: 0.72)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: highlighted && !drink.featured
            ? PremiumEffects.hoverGlow(intensity: 0.35)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  DrinkSelectionCheckbox(
                    key: Key('drink_select_${drink.id}'),
                    value: widget.isSelected,
                    semanticLabel: 'Select ${drink.name}',
                    onChanged: widget.onSelectionChanged,
                  ),
                  Expanded(
                    child: InlineEditableTextCell(
                      value: drink.name,
                      displayStyle: InlineEditCellTheme.titleDisplayTextStyle
                          .copyWith(letterSpacing: drink.featured ? 0.15 : 0),
                      hintText: 'Drink name',
                      onAdvancedEdit: widget.onAdvancedEdit,
                      validate: AddDrinkFormValidator.validateName,
                      onSave: (value) => _patch(BulkDrinkPatch(name: value)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.lg,
              ),
              child: InlineEditableDropdownCell<String>(
                value: _categoryDisplay(),
                items: DrinkCategories.all,
                displayLabel: (value) => value,
                validate: AddDrinkFormValidator.validateCategory,
                onSave: (value) => _patch(BulkDrinkPatch(category: value)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.lg,
              ),
              child: InlineEditablePriceCell(
                price: drink.price,
                displayText: drink.formattedPrice,
                onSave: (price) => _patch(BulkDrinkPatch(price: price)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.lg,
              ),
              child: InlineEditableToggleCell(
                value: drink.available,
                onSave: (value) => _patch(BulkDrinkPatch(available: value)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.lg,
              ),
              child: InlineEditableToggleCell(
                value: drink.featured,
                onSave: (value) {
                  final limitError = _validateFeatured(value);
                  if (limitError != null) return Future.value(limitError);
                  return _patch(BulkDrinkPatch(featured: value));
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.lg,
              ),
              child: Text(
                drink.updatedAt == null
                    ? '—'
                    : VenueDrinksRepository.relativeTimeLabel(drink.updatedAt!),
                style: TextStyle(
                  color: drink.updatedAt == null
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                  fontStyle:
                      drink.updatedAt == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
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
          child: drink.featured
              ? Padding(
                  key: drinkRowFeaturedBorderKey(drink.id),
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

/// Column headers for the drinks management table.
class DrinkTableHeader extends StatelessWidget {
  const DrinkTableHeader({
    super.key,
    required this.sort,
    required this.onSortColumn,
  });

  final DrinkTableSort sort;
  final ValueChanged<DrinkSortColumn> onSortColumn;

  static const _sortableColumns = [
    DrinkSortColumn.name,
    DrinkSortColumn.category,
    DrinkSortColumn.price,
    DrinkSortColumn.available,
    DrinkSortColumn.featured,
  ];

  static const _trailingLabel = 'Last updated';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final column in _sortableColumns)
              Expanded(
                flex: column == DrinkSortColumn.name ? 2 : 1,
                child: _SortableHeaderCell(
                  label: drinkSortColumnLabel(column),
                  column: column,
                  sort: sort,
                  onSortColumn: onSortColumn,
                  padding: EdgeInsets.fromLTRB(
                    column == DrinkSortColumn.name
                        ? AppSpacing.sm + 18 + AppSpacing.sm
                        : AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  _trailingLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
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
  final DrinkSortColumn column;
  final DrinkTableSort sort;
  final ValueChanged<DrinkSortColumn> onSortColumn;
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
        ? (widget.sort.direction == DrinkSortDirection.ascending
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded)
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: drinkSortColumnKey(widget.column),
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
                  key: drinkSortIndicatorKey(widget.column),
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
