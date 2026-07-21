import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venue/data/models/deal_model.dart';
import '../../../venue/data/venue_deals_repository.dart';
import '../../models/featured_deals_limit.dart';
import 'bulk_edit_deals_table.dart';

Future<bool> showBulkEditDealsDialog(
  BuildContext context, {
  required List<DealModel> deals,
  required List<DealModel> venueDeals,
  required String venueName,
  required VenueDealsRepository repository,
  String? testUpdatedBy,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BulkEditDealsDialog(
      deals: deals,
      venueDeals: venueDeals,
      venueName: venueName,
      repository: repository,
      testUpdatedBy: testUpdatedBy,
    ),
  ).then((value) => value ?? false);
}

class BulkEditDealsDialog extends StatefulWidget {
  const BulkEditDealsDialog({
    super.key,
    required this.deals,
    required this.venueDeals,
    required this.venueName,
    required this.repository,
    this.testUpdatedBy,
  });

  final List<DealModel> deals;
  final List<DealModel> venueDeals;
  final String venueName;
  final VenueDealsRepository repository;
  final String? testUpdatedBy;

  @override
  State<BulkEditDealsDialog> createState() => _BulkEditDealsDialogState();
}

class _BulkEditDealsDialogState extends State<BulkEditDealsDialog> {
  late final List<BulkDealEditRowState> _rows =
      widget.deals.map(BulkDealEditRowState.fromDeal).toList();

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
      final titleError = row.validateTitle();
      if (titleError != null) return titleError;

      final typeError = row.validateDealType();
      if (typeError != null) return typeError;

      final valueError = row.validateValue();
      if (valueError != null) return valueError;
    }

    final featuredLimitError = FeaturedDealsLimit.validateBulkEdit(
      selectedDeals: widget.deals,
      venueDeals: widget.venueDeals,
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
      setState(() => _errorMessage = 'You must be signed in to edit deals.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      for (final row in _rows) {
        await widget.repository.updateDeal(
          dealId: row.dealId,
          venueId: widget.deals.first.venueId,
          venueName: widget.venueName,
          title: row.titleController.text,
          description: row.description,
          dealType: row.dealType!,
          value: row.valueController.text,
          startDateTime: row.startDateTime ?? DateTime.now(),
          endDateTime: row.endDateTime ?? DateTime.now().add(const Duration(days: 1)),
          availableDays: row.availableDays,
          startTime: row.startTime,
          endTime: row.endTime,
          isActive: row.isActive,
          featured: row.featured,
          updatedBy: userId,
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
                'Bulk Edit Deals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Edit ${widget.deals.length} selected deals.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: BulkEditDealsTable(
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
