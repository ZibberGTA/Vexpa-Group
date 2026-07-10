import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../models/drink_categories.dart';

/// Shared drink form fields for add and edit modals.
class DrinkForm extends StatelessWidget {
  const DrinkForm({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.available,
    required this.featured,
    required this.onCategoryChanged,
    required this.onAvailableChanged,
    required this.onFeaturedChanged,
    required this.onOpenSupport,
    this.enabled = true,
    this.showSupportLink = true,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController descriptionController;
  final String? selectedCategory;
  final bool available;
  final bool featured;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool> onAvailableChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final VoidCallback onOpenSupport;
  final bool enabled;
  final bool showSupportLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Drink Name',
            hintText: 'Espresso Martini',
          ),
          validator: AddDrinkFormValidator.validateName,
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
          ),
          items: DrinkCategories.all
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ),
              )
              .toList(),
          onChanged: enabled ? onCategoryChanged : null,
          validator: AddDrinkFormValidator.validateCategory,
        ),
        if (showSupportLink) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Need another category? ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              InkWell(
                onTap: enabled ? onOpenSupport : null,
                child: Text(
                  'Raise a support ticket.',
                  style: TextStyle(
                    color: AppColors.primaryPink.withValues(alpha: 0.95),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: priceController,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Price (optional)',
            hintText: '9.50',
            prefixText: '£ ',
          ),
          validator: AddDrinkFormValidator.validatePrice,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: descriptionController,
          enabled: enabled,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'Add a short description customers will see.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Available',
              style: TextStyle(color: AppColors.white),
            ),
            value: available,
            activeThumbColor: AppColors.primaryPink,
            onChanged: enabled ? onAvailableChanged : null,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Featured',
              style: TextStyle(color: AppColors.white),
            ),
            value: featured,
            activeThumbColor: AppColors.primaryPink,
            onChanged: enabled ? onFeaturedChanged : null,
          ),
        ),
      ],
    );
  }
}
