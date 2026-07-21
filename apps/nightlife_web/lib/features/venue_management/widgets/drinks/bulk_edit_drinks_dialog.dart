import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venue/data/models/drink_model.dart';
import '../../../venue/data/venue_drinks_repository.dart';
import '../../models/featured_drinks_limit.dart';
import 'bulk_edit_drinks_table.dart';

Future<bool> showBulkEditDrinksDialog(
  BuildContext context, {
  required List<DrinkModel> drinks,
  required List<DrinkModel> venueDrinks,
  required String venueName,
  required VenueDrinksRepository repository,
  String? testUpdatedBy,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BulkEditDrinksDialog(
      drinks: drinks,
      venueDrinks: venueDrinks,
      venueName: venueName,
      repository: repository,
      testUpdatedBy: testUpdatedBy,
    ),
  ).then((value) => value ?? false);
}

class BulkEditDrinksDialog extends StatefulWidget {
  const BulkEditDrinksDialog({
    super.key,
    required this.drinks,
    required this.venueDrinks,
    required this.venueName,
    required this.repository,
    this.testUpdatedBy,
  });

  final List<DrinkModel> drinks;
  final List<DrinkModel> venueDrinks;
  final String venueName;
  final VenueDrinksRepository repository;
  final String? testUpdatedBy;

  @override
  State<BulkEditDrinksDialog> createState() => _BulkEditDrinksDialogState();
}

class _BulkEditDrinksDialogState extends State<BulkEditDrinksDialog> {
  late final List<BulkDrinkEditRowState> _rows =
      widget.drinks.map(BulkDrinkEditRowState.fromDrink).toList();

  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  String? _resolveUserId() {
    if (widget.testUpdatedBy != null) return widget.testUpdatedBy;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String? _validateRows() {
    for (final row in _rows) {
      final nameError = row.validateName();
      if (nameError != null) return nameError;

      final categoryError = row.validateCategory();
      if (categoryError != null) return categoryError;

      final priceError = row.validatePrice();
      if (priceError != null) return priceError;
    }

    final featuredLimitError = FeaturedDrinksLimit.validateBulkEdit(
      selectedDrinks: widget.drinks,
      venueDrinks: widget.venueDrinks,
      proposedFeaturedValues: _rows.map((row) => row.featured),
    );
    if (featuredLimitError != null) return featuredLimitError;

    return null;
  }

  Future<void> _submit() async {
    if (_saving) return;

    final validationError = _validateRows();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    final userId = _resolveUserId();
    if (userId == null) {
      setState(() => _errorMessage = 'You must be signed in to edit drinks.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      for (final row in _rows) {
        await widget.repository.updateDrink(
          drinkId: row.drinkId,
          venueId: widget.drinks.first.venueId,
          venueName: widget.venueName,
          name: row.nameController.text,
          category: row.category!,
          description: row.description,
          available: row.available,
          featured: row.featured,
          updatedBy: userId,
          price: row.parsePrice(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Could not save changes. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 640),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bulk Edit Drinks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Edit ${widget.drinks.length} selected drinks. '
                'Each row updates the existing drink document.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: BulkEditDrinksTable(
                    rows: _rows,
                    enabled: !_saving,
                    onRowChanged: () => setState(() {}),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontSize: 13.5,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: DrinkSpotButton(
                      label: 'Cancel',
                      variant: DrinkSpotButtonVariant.ghost,
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DrinkSpotButton(
                      label: _saving ? 'Saving…' : 'Save Changes',
                      icon: _saving ? null : Icons.save_outlined,
                      compact: true,
                      onPressed: _saving ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
