import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venue/data/models/deal_model.dart';
import '../../../venue/data/venue_deals_repository.dart';
import '../../data/deal_write_payload.dart';
import '../../models/deal_types.dart';
import '../../models/featured_deals_limit.dart';
import '../venue_dashboard_controller.dart';
import 'delete_deal_confirmation_dialog.dart';
import 'deal_form.dart';

enum DealEditResult { updated, deleted }

Future<DealEditResult?> showEditDealDialog(
  BuildContext context, {
  required DealModel deal,
  VenueDealsRepository? repository,
  String? testUpdatedBy,
  List<DealModel> venueDeals = const [],
}) {
  final controller = VenueDashboardController.maybeOf(context);
  final contextData = controller?.contextData;
  if (contextData == null) return Future.value(null);

  return showDialog<DealEditResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => EditDealDialog(
      deal: deal,
      venueName: contextData.venueName,
      repository: repository ?? VenueDealsRepository(),
      venueDeals: venueDeals,
      testUpdatedBy: testUpdatedBy,
    ),
  );
}

class EditDealDialog extends StatefulWidget {
  const EditDealDialog({
    super.key,
    required this.deal,
    required this.venueName,
    required this.repository,
    this.venueDeals = const [],
    this.testUpdatedBy,
  });

  final DealModel deal;
  final String venueName;
  final VenueDealsRepository repository;
  final List<DealModel> venueDeals;
  final String? testUpdatedBy;

  @override
  State<EditDealDialog> createState() => _EditDealDialogState();
}

class _EditDealDialogState extends State<EditDealDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _valueController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;

  late String? _selectedDealType;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late final Set<String> _availableDays;
  late bool _isActive;
  late bool _featured;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final deal = widget.deal;
    _titleController = TextEditingController(text: deal.title);
    _descriptionController = TextEditingController(text: deal.description);
    _valueController = TextEditingController(text: deal.value);
    _startTimeController = TextEditingController(text: deal.startTime);
    _endTimeController = TextEditingController(text: deal.endTime);
    _selectedDealType = DealTypes.normalize(deal.dealType);
    _startDate = deal.startDateTime;
    _endDate = deal.endDateTime;
    _availableDays = Set.of(deal.availableDays);
    _isActive = deal.isActive;
    _featured = deal.featured;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
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

    final dateError = validateDealDateRange(_startDate, _endDate);
    if (dateError != null) {
      setState(() => _errorMessage = dateError);
      return;
    }

    final featuredLimitError = FeaturedDealsLimit.validateEdit(
      deal: widget.deal,
      wantsFeatured: _featured,
      venueDeals: widget.venueDeals,
    );
    if (featuredLimitError != null) {
      setState(() => _errorMessage = featuredLimitError);
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
      await widget.repository.updateDeal(
        dealId: widget.deal.id,
        venueId: widget.deal.venueId,
        venueName: widget.venueName,
        title: _titleController.text,
        description: _descriptionController.text,
        dealType: _selectedDealType!,
        value: _valueController.text,
        startDateTime: combineDealDateAndTime(_startDate!, _startTimeController.text),
        endDateTime: combineDealDateAndTime(_endDate!, _endTimeController.text),
        availableDays: _availableDays.toList(),
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        isActive: _isActive,
        featured: _featured,
        updatedBy: userId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(DealEditResult.updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Could not save changes. Please try again.';
      });
    }
  }

  Future<void> _confirmDelete() async {
    if (_saving) return;

    final confirmed = await DeleteDealConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    final userId = _resolveUserId();
    if (userId == null) {
      setState(() => _errorMessage = 'You must be signed in to delete deals.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.deleteDeal(
        dealId: widget.deal.id,
        deletedBy: userId,
        deletedByEmail: _resolveUserEmail(),
        venueId: widget.deal.venueId,
        dealTitle: widget.deal.title,
      );

      if (!mounted) return;
      Navigator.of(context).pop(DealEditResult.deleted);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Could not delete deal. Please try again.';
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
                    'Edit Deal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  DealForm(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    valueController: _valueController,
                    startTimeController: _startTimeController,
                    endTimeController: _endTimeController,
                    selectedDealType: _selectedDealType,
                    startDate: _startDate,
                    endDate: _endDate,
                    availableDays: _availableDays,
                    isActive: _isActive,
                    featured: _featured,
                    enabled: !_saving,
                    onDealTypeChanged: (value) =>
                        setState(() => _selectedDealType = value),
                    onStartDateChanged: (value) =>
                        setState(() => _startDate = value),
                    onEndDateChanged: (value) => setState(() => _endDate = value),
                    onAvailableDayToggled: (day, selected) {
                      setState(() {
                        if (selected) {
                          _availableDays.add(day);
                        } else {
                          _availableDays.remove(day);
                        }
                      });
                    },
                    onActiveChanged: (value) => setState(() => _isActive = value),
                    onFeaturedChanged: (value) =>
                        setState(() => _featured = value),
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
                        'Delete Deal',
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
