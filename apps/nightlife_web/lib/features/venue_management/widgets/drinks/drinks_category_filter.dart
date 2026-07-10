import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../models/drink_categories.dart';

/// All + multi-select category filter row for drinks management.
class DrinksCategoryFilterRow extends StatelessWidget {
  const DrinksCategoryFilterRow({
    super.key,
    required this.selectedCategories,
    required this.onAllSelected,
    required this.onCategoryToggled,
  });

  final Set<String> selectedCategories;
  final VoidCallback onAllSelected;
  final void Function(String category, bool selected) onCategoryToggled;

  String get _categoriesButtonLabel {
    final count = selectedCategories.length;
    if (count == 0) return 'Categories';
    return 'Categories ($count)';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DrinksFilterChip(
          label: 'All',
          selected: selectedCategories.isEmpty,
          onTap: onAllSelected,
        ),
        _DrinksCategoriesDropdown(
          key: const Key('drinks_categories_filter_button'),
          label: _categoriesButtonLabel,
          selectedCategories: selectedCategories,
          onCategoryToggled: onCategoryToggled,
        ),
      ],
    );
  }
}

class _DrinksCategoriesDropdown extends StatelessWidget {
  const _DrinksCategoriesDropdown({
    super.key,
    required this.label,
    required this.selectedCategories,
    required this.onCategoryToggled,
  });

  final String label;
  final Set<String> selectedCategories;
  final void Function(String category, bool selected) onCategoryToggled;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          AppColors.surfaceElevated.withValues(alpha: 0.98),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(
              color: AppColors.primaryPurple.withValues(alpha: 0.24),
            ),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
        maximumSize: const WidgetStatePropertyAll(Size(280, 340)),
      ),
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320, minWidth: 248),
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final category in DrinkCategories.all)
                  _CategoryCheckboxMenuItem(
                    key: Key('drinks_category_filter_$category'),
                    category: category,
                    selected: selectedCategories.contains(category),
                    onChanged: (selected) => onCategoryToggled(category, selected),
                  ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return _DrinksFilterChip(
          label: label,
          selected: selectedCategories.isNotEmpty,
          showDropdownArrow: true,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }
}

class _CategoryCheckboxMenuItem extends StatelessWidget {
  const _CategoryCheckboxMenuItem({
    super.key,
    required this.category,
    required this.selected,
    required this.onChanged,
  });

  final String category;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!selected),
        hoverColor: AppColors.primaryPurple.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: selected,
                  onChanged: (value) => onChanged(value ?? false),
                  activeColor: AppColors.primaryPink,
                  side: BorderSide(
                    color: AppColors.primaryPurple.withValues(alpha: 0.45),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrinksFilterChip extends StatefulWidget {
  const _DrinksFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDropdownArrow = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDropdownArrow;

  @override
  State<_DrinksFilterChip> createState() => _DrinksFilterChipState();
}

class _DrinksFilterChipState extends State<_DrinksFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PremiumEffects.fast,
          curve: PremiumEffects.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, highlighted && !widget.selected ? -1.0 : 0.0),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: widget.selected ? AppColors.brandGradient : null,
            color: widget.selected
                ? null
                : AppColors.surfaceElevated.withValues(alpha: 0.78),
            border: Border.all(
              color: widget.selected
                  ? Colors.transparent
                  : highlighted
                      ? AppColors.primaryPink.withValues(alpha: 0.28)
                      : AppColors.primaryPurple.withValues(alpha: 0.18),
            ),
            boxShadow: widget.selected || (highlighted && !widget.selected)
                ? PremiumEffects.hoverGlow(intensity: widget.selected ? 0.45 : 0.2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              if (widget.showDropdownArrow) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: widget.selected
                      ? AppColors.white
                      : AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
