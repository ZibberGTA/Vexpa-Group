import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';

/// Confirmation dialog before bulk deleting drinks.
class BulkDeleteDrinksConfirmationDialog extends StatelessWidget {
  const BulkDeleteDrinksConfirmationDialog({
    super.key,
    required this.drinkCount,
  });

  final int drinkCount;

  static Future<bool> show(BuildContext context, {required int drinkCount}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BulkDeleteDrinksConfirmationDialog(drinkCount: drinkCount),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Delete Drinks?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You are about to permanently delete $drinkCount drink(s). '
                'This action cannot be undone.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              DrinkSpotButton(
                label: 'Cancel',
                variant: DrinkSpotButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: AppSpacing.sm),
              DrinkSpotButton(
                key: const Key('confirm_bulk_delete_drinks_button'),
                label: 'Delete Drinks',
                variant: DrinkSpotButtonVariant.secondary,
                compact: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
