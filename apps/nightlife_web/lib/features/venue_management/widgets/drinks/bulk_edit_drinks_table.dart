import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../venue/data/models/drink_model.dart';
import '../../models/drink_categories.dart';

/// Editable row state for bulk drink editing.
class BulkDrinkEditRowState {
  BulkDrinkEditRowState({
    required this.drinkId,
    required this.description,
    required this.nameController,
    required this.priceController,
    required this.category,
    required this.available,
    required this.featured,
  });

  final String drinkId;
  final String description;
  final TextEditingController nameController;
  final TextEditingController priceController;
  String? category;
  bool available;
  bool featured;

  factory BulkDrinkEditRowState.fromDrink(DrinkModel drink) {
    var category = DrinkCategories.displayName(drink.category);
    if (!DrinkCategories.isAllowed(category)) {
      category = 'Other';
    }

    return BulkDrinkEditRowState(
      drinkId: drink.id,
      description: drink.description,
      nameController: TextEditingController(text: drink.name),
      priceController: TextEditingController(
        text: drink.price > 0 ? drink.price.toStringAsFixed(2) : '',
      ),
      category: category,
      available: drink.available,
      featured: drink.featured,
    );
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }

  String? validateName() => AddDrinkFormValidator.validateName(nameController.text);

  String? validateCategory() => AddDrinkFormValidator.validateCategory(category);

  String? validatePrice() => AddDrinkFormValidator.validatePrice(priceController.text);

  double? parsePrice() {
    final trimmed = priceController.text.trim().replaceAll('£', '');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
}

/// Compressed editable table for bulk drink edits.
class BulkEditDrinksTable extends StatelessWidget {
  const BulkEditDrinksTable({
    super.key,
    required this.rows,
    required this.enabled,
    required this.onRowChanged,
  });

  final List<BulkDrinkEditRowState> rows;
  final bool enabled;
  final VoidCallback onRowChanged;

  static const _tableMinWidth = 780.0;

  static const _nameFlex = 24;
  static const _categoryFlex = 20;
  static const _priceFlex = 12;
  static const _toggleFlex = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < _tableMinWidth
            ? _tableMinWidth
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _BulkEditDrinksTableHeader(),
                for (var i = 0; i < rows.length; i++)
                  _BulkEditDrinksTableRow(
                    row: rows[i],
                    enabled: enabled,
                    onChanged: onRowChanged,
                    showDivider: i < rows.length - 1,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BulkEditDrinksTableHeader extends StatelessWidget {
  const _BulkEditDrinksTableHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            _HeaderCell(label: 'Drink Name', flex: BulkEditDrinksTable._nameFlex),
            _HeaderCell(label: 'Category', flex: BulkEditDrinksTable._categoryFlex),
            _HeaderCell(label: 'Price', flex: BulkEditDrinksTable._priceFlex),
            _HeaderCell(
              label: 'Available',
              flex: BulkEditDrinksTable._toggleFlex,
              centered: true,
            ),
            _HeaderCell(
              label: 'Featured',
              flex: BulkEditDrinksTable._toggleFlex,
              centered: true,
            ),
          ],
        ),
        Divider(color: AppColors.primaryPurple.withValues(alpha: 0.16)),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.flex,
    this.centered = false,
  });

  final String label;
  final int flex;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _BulkEditDrinksTableRow extends StatelessWidget {
  const _BulkEditDrinksTableRow({
    required this.row,
    required this.enabled,
    required this.onChanged,
    required this.showDivider,
  });

  final BulkDrinkEditRowState row;
  final bool enabled;
  final VoidCallback onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.surfaceElevated.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.22),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.22),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: BulkEditDrinksTable._nameFlex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: TextField(
                    controller: row.nameController,
                    enabled: enabled,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: inputDecoration.copyWith(hintText: 'Drink name'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ),
              Expanded(
                flex: BulkEditDrinksTable._categoryFlex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: DropdownButtonFormField<String>(
                    value: row.category,
                    isDense: true,
                    isExpanded: true,
                    decoration: inputDecoration,
                    items: DrinkCategories.all
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: enabled
                        ? (value) {
                            row.category = value;
                            onChanged();
                          }
                        : null,
                  ),
                ),
              ),
              Expanded(
                flex: BulkEditDrinksTable._priceFlex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: TextField(
                    controller: row.priceController,
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                    decoration: inputDecoration.copyWith(
                      hintText: '9.50',
                      prefixText: '£ ',
                      prefixStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ),
              Expanded(
                flex: BulkEditDrinksTable._toggleFlex,
                child: Center(
                  child: Transform.scale(
                    scale: 0.78,
                    child: Switch(
                      value: row.available,
                      activeThumbColor: AppColors.primaryPink,
                      onChanged: enabled
                          ? (value) {
                              row.available = value;
                              onChanged();
                            }
                          : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: BulkEditDrinksTable._toggleFlex,
                child: Center(
                  child: Transform.scale(
                    scale: 0.78,
                    child: Switch(
                      value: row.featured,
                      activeThumbColor: AppColors.primaryPink,
                      onChanged: enabled
                          ? (value) {
                              row.featured = value;
                              onChanged();
                            }
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: AppColors.primaryPurple.withValues(alpha: 0.1)),
      ],
    );
  }
}
