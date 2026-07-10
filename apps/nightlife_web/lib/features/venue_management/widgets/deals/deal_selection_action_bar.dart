import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';

/// Compact action bar shown when deals are selected.
class DealSelectionActionBar extends StatelessWidget {
  const DealSelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onEdit,
    required this.onDelete,
    required this.onClearSelection,
  });

  final int selectedCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      borderRadius: AppSpacing.radiusMd,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      interactiveHover: true,
      child: Row(
        children: [
          Text(
            'Selected: $selectedCount',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          const Spacer(),
          DrinkSpotButton(
            label: 'Edit Deals',
            icon: Icons.edit_outlined,
            compact: true,
            variant: DrinkSpotButtonVariant.secondary,
            onPressed: onEdit,
          ),
          const SizedBox(width: AppSpacing.sm),
          DrinkSpotButton(
            label: 'Delete Deals',
            icon: Icons.delete_outline_rounded,
            compact: true,
            variant: DrinkSpotButtonVariant.secondary,
            onPressed: onDelete,
          ),
          const SizedBox(width: AppSpacing.sm),
          DrinkSpotButton(
            label: 'Clear Selection',
            icon: Icons.deselect_outlined,
            compact: true,
            variant: DrinkSpotButtonVariant.secondary,
            onPressed: onClearSelection,
          ),
        ],
      ),
    );
  }
}
