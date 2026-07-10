import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';

/// Confirmation dialog before deleting a drink.
class DeleteDrinkConfirmationDialog extends StatelessWidget {
  const DeleteDrinkConfirmationDialog({super.key});

  static Future<bool> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteDrinkConfirmationDialog(),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Delete Drink?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Are you sure you want to delete this drink? This action cannot be undone.',
                style: TextStyle(
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
                key: const Key('confirm_delete_drink_button'),
                label: 'Delete Drink',
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
