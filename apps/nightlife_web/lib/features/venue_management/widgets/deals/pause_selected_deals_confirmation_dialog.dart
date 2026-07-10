import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';

/// Confirmation dialog before pausing selected deals.
class PauseSelectedDealsConfirmationDialog extends StatelessWidget {
  const PauseSelectedDealsConfirmationDialog({super.key, required this.dealCount});

  final int dealCount;

  static Future<bool> show(BuildContext context, {required int dealCount}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PauseSelectedDealsConfirmationDialog(dealCount: dealCount),
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
                'Pause Selected Deals?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                dealCount == 1
                    ? 'This deal will no longer be visible to customers.'
                    : 'These $dealCount deals will no longer be visible to customers.',
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
                key: const Key('confirm_pause_selected_deals_button'),
                label: 'Pause Deals',
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
