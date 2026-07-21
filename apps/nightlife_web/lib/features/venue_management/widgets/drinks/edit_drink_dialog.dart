import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venue/data/models/drink_model.dart';
import '../../../venue/data/venue_drinks_repository.dart';
import '../../models/drink_categories.dart';
import '../../models/featured_drinks_limit.dart';
import '../../models/venue_dashboard_tab.dart';
import '../venue_dashboard_controller.dart';
import 'delete_drink_confirmation_dialog.dart';
import 'drink_form.dart';

enum DrinkEditResult { updated, deleted }

/// Opens the Edit Drink modal for the selected drink.
Future<DrinkEditResult?> showEditDrinkDialog(
  BuildContext context, {
  required DrinkModel drink,
  VenueDrinksRepository? repository,
  String? testUpdatedBy,
  List<DrinkModel> venueDrinks = const [],
}) {
  final controller = VenueDashboardController.maybeOf(context);
  final contextData = controller?.contextData;
  if (contextData == null) return Future.value(null);

  return showDialog<DrinkEditResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => DrinkEditModal(
      drink: drink,
      venueName: contextData.venueName,
      repository: repository ?? VenueDrinksRepository(),
      venueDrinks: venueDrinks,
      testUpdatedBy: testUpdatedBy,
      onOpenSupport: () {
        Navigator.of(dialogContext).pop(null);
        controller?.selectTab(VenueDashboardTab.support);
      },
    ),
  );
}

/// Edit Drink modal with save and delete actions.
class DrinkEditModal extends StatefulWidget {
  const DrinkEditModal({
    super.key,
    required this.drink,
    required this.venueName,
    required this.repository,
    required this.onOpenSupport,
    this.venueDrinks = const [],
    this.testUpdatedBy,
  });

  final DrinkModel drink;
  final String venueName;
  final VenueDrinksRepository repository;
  final VoidCallback onOpenSupport;
  final List<DrinkModel> venueDrinks;
  final String? testUpdatedBy;

  @override
  State<DrinkEditModal> createState() => _DrinkEditModalState();
}

class _DrinkEditModalState extends State<DrinkEditModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  late String? _selectedCategory;
  late bool _available;
  late bool _featured;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final drink = widget.drink;
    _nameController = TextEditingController(text: drink.name);
    _priceController = TextEditingController(
      text: drink.price > 0 ? drink.price.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(text: drink.description);
    _selectedCategory = DrinkCategories.displayName(drink.category);
    if (!DrinkCategories.isAllowed(_selectedCategory!)) {
      _selectedCategory = 'Other';
    }
    _available = drink.available;
    _featured = drink.featured;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double? _parsePrice() {
    final trimmed = _priceController.text.trim().replaceAll('£', '');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  String? _resolveUserId() {
    return widget.testUpdatedBy ?? FirebaseAuth.instance.currentUser?.uid;
  }

  String? _resolveUserEmail() {
    try {
      return FirebaseAuth.instance.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final featuredLimitError = FeaturedDrinksLimit.validateEdit(
      drink: widget.drink,
      wantsFeatured: _featured,
      venueDrinks: widget.venueDrinks,
    );
    if (featuredLimitError != null) {
      setState(() => _errorMessage = featuredLimitError);
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
      await widget.repository.updateDrink(
        drinkId: widget.drink.id,
        venueId: widget.drink.venueId,
        venueName: widget.venueName,
        name: _nameController.text,
        category: _selectedCategory!,
        description: _descriptionController.text,
        available: _available,
        featured: _featured,
        updatedBy: userId,
        price: _parsePrice(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(DrinkEditResult.updated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Could not save changes. Please try again.';
      });
    }
  }

  Future<void> _confirmDelete() async {
    if (_saving) return;

    final confirmed = await DeleteDrinkConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    final userId = _resolveUserId();
    if (userId == null) {
      setState(() => _errorMessage = 'You must be signed in to delete drinks.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.deleteDrink(
        drinkId: widget.drink.id,
        deletedBy: userId,
        deletedByEmail: _resolveUserEmail(),
        venueId: widget.drink.venueId,
        drinkName: widget.drink.name,
      );

      if (!mounted) return;
      Navigator.of(context).pop(DrinkEditResult.deleted);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Could not delete drink. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Drink',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  DrinkForm(
                    nameController: _nameController,
                    priceController: _priceController,
                    descriptionController: _descriptionController,
                    selectedCategory: _selectedCategory,
                    available: _available,
                    featured: _featured,
                    enabled: !_saving,
                    onCategoryChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    onAvailableChanged: (value) =>
                        setState(() => _available = value),
                    onFeaturedChanged: (value) =>
                        setState(() => _featured = value),
                    onOpenSupport: widget.onOpenSupport,
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
                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _saving ? null : _confirmDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.primaryPink.withValues(alpha: 0.9),
                      ),
                      label: Text(
                        'Delete Drink',
                        style: TextStyle(
                          color: AppColors.primaryPink.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: DrinkSpotButton(
                          label: 'Cancel',
                          variant: DrinkSpotButtonVariant.ghost,
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(null),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DrinkSpotButton(
                          label: _saving ? 'Saving…' : 'Save Changes',
                          icon: _saving ? null : Icons.save_outlined,
                          onPressed: _saving ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
