import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venue/data/models/drink_model.dart';
import '../../../venue/data/models/drink_model.dart';
import '../../../venue/data/venue_drinks_repository.dart';
import '../../models/featured_drinks_limit.dart';
import '../../models/venue_dashboard_tab.dart';
import '../venue_dashboard_controller.dart';
import 'drink_form.dart';

/// Opens the Add Drink modal for the active venue.
Future<bool> showAddDrinkDialog(
  BuildContext context, {
  VenueDrinksRepository? repository,
  String? testCreatedBy,
  List<DrinkModel> venueDrinks = const [],
}) {
  final controller = VenueDashboardController.maybeOf(context);
  final contextData = controller?.contextData;
  if (contextData == null) return Future.value(false);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AddDrinkDialog(
      venueId: contextData.venueId,
      venueName: contextData.venueName,
      repository: repository ?? VenueDrinksRepository(),
      venueDrinks: venueDrinks,
      testCreatedBy: testCreatedBy,
      onOpenSupport: () {
        Navigator.of(dialogContext).pop(false);
        controller?.selectTab(VenueDashboardTab.support);
      },
    ),
  ).then((value) => value ?? false);
}

class AddDrinkDialog extends StatefulWidget {
  const AddDrinkDialog({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.repository,
    required this.onOpenSupport,
    this.venueDrinks = const [],
    this.testCreatedBy,
  });

  final String venueId;
  final String venueName;
  final VenueDrinksRepository repository;
  final VoidCallback onOpenSupport;
  final List<DrinkModel> venueDrinks;
  final String? testCreatedBy;

  @override
  State<AddDrinkDialog> createState() => _AddDrinkDialogState();
}

class _AddDrinkDialogState extends State<AddDrinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  bool _available = true;
  bool _featured = false;
  bool _saving = false;
  String? _errorMessage;

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

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final featuredLimitError = FeaturedDrinksLimit.validateAdd(
      wantsFeatured: _featured,
      venueDrinks: widget.venueDrinks,
    );
    if (featuredLimitError != null) {
      setState(() => _errorMessage = featuredLimitError);
      return;
    }

    final userId =
        widget.testCreatedBy ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _errorMessage = 'You must be signed in to add drinks.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.addDrink(
        venueId: widget.venueId,
        venueName: widget.venueName,
        name: _nameController.text,
        category: _selectedCategory!,
        description: _descriptionController.text,
        available: _available,
        featured: _featured,
        createdBy: userId,
        price: _parsePrice(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Could not save drink. Please try again.';
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
                    'Add Drink',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Add a drink to your venue menu.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.5,
                      height: 1.5,
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
                          label: _saving ? 'Adding…' : 'Add Drink',
                          icon: _saving ? null : Icons.add_rounded,
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
