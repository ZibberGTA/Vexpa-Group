import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';

/// Confirmation dialog before deleting a deal.
class DeleteDealConfirmationDialog extends StatelessWidget {
  const DeleteDealConfirmationDialog({super.key});

  static Future<bool> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteDealConfirmationDialog(),
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
                'Delete Deal?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Are you sure you want to delete this deal? This action cannot be undone.',
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
                key: const Key('confirm_delete_deal_button'),
                label: 'Delete Deal',
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

/// Confirmation dialog before bulk deleting deals.
class BulkDeleteDealsConfirmationDialog extends StatelessWidget {
  const BulkDeleteDealsConfirmationDialog({super.key, required this.dealCount});

  final int dealCount;

  static Future<bool> show(BuildContext context, {required int dealCount}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BulkDeleteDealsConfirmationDialog(dealCount: dealCount),
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
                'Delete Deals?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                dealCount == 1
                    ? 'Are you sure you want to delete this deal? This action cannot be undone.'
                    : 'Are you sure you want to delete $dealCount deals? This action cannot be undone.',
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
                key: const Key('confirm_bulk_delete_deals_button'),
                label: 'Delete Deals',
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
