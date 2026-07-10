import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venue/data/models/deal_model.dart';
import '../../../venue/data/venue_deals_repository.dart';
import '../../data/deal_write_payload.dart';
import '../../models/featured_deals_limit.dart';
import '../venue_dashboard_controller.dart';
import 'deal_form.dart';

Future<bool> showAddDealDialog(
  BuildContext context, {
  VenueDealsRepository? repository,
  String? testCreatedBy,
  List<DealModel> venueDeals = const [],
  DateTime? testStartDate,
  DateTime? testEndDate,
}) {
  final controller = VenueDashboardController.maybeOf(context);
  final contextData = controller?.contextData;
  if (contextData == null) return Future.value(false);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AddDealDialog(
      venueId: contextData.venueId,
      venueName: contextData.venueName,
      repository: repository ?? VenueDealsRepository(),
      venueDeals: venueDeals,
      testCreatedBy: testCreatedBy,
      testStartDate: testStartDate,
      testEndDate: testEndDate,
    ),
  ).then((value) => value ?? false);
}

class AddDealDialog extends StatefulWidget {
  const AddDealDialog({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.repository,
    this.venueDeals = const [],
    this.testCreatedBy,
    this.testStartDate,
    this.testEndDate,
  });

  final String venueId;
  final String venueName;
  final VenueDealsRepository repository;
  final List<DealModel> venueDeals;
  final String? testCreatedBy;
  final DateTime? testStartDate;
  final DateTime? testEndDate;

  @override
  State<AddDealDialog> createState() => _AddDealDialogState();
}

class _AddDealDialogState extends State<AddDealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  String? _selectedDealType;
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _availableDays = {};
  bool _isActive = true;
  bool _featured = false;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startDate = widget.testStartDate;
    _endDate = widget.testEndDate;
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

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final dateError = validateDealDateRange(_startDate, _endDate);
    if (dateError != null) {
      setState(() => _errorMessage = dateError);
      return;
    }

    final featuredLimitError = FeaturedDealsLimit.validateAdd(
      wantsFeatured: _featured,
      venueDeals: widget.venueDeals,
    );
    if (featuredLimitError != null) {
      setState(() => _errorMessage = featuredLimitError);
      return;
    }

    final userId =
        widget.testCreatedBy ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _errorMessage = 'You must be signed in to create deals.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.addDeal(
        venueId: widget.venueId,
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
        createdBy: userId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Could not save deal. Please try again.';
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
                    'Create Deal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Add a promotional offer for your venue.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.5,
                      height: 1.5,
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
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: DrinkSpotButton(
                          label: 'Cancel',
                          variant: DrinkSpotButtonVariant.ghost,
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DrinkSpotButton(
                          key: const Key('create_deal_submit_button'),
                          label: _saving ? 'Creating…' : 'Create Deal',
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
