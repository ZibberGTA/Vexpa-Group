import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venue/data/models/event_model.dart';
import '../../../venue/data/venue_events_repository.dart';
import '../../models/featured_events_limit.dart';
import '../venue_dashboard_controller.dart';
import 'event_form.dart';

Future<bool> showAddEventDialog(
  BuildContext context, {
  VenueEventsRepository? repository,
  String? testCreatedBy,
  List<EventModel> venueEvents = const [],
  DateTime? testStartDate,
  DateTime? testEndDate,
}) {
  final controller = VenueDashboardController.maybeOf(context);
  final contextData = controller?.contextData;
  if (contextData == null) return Future.value(false);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AddEventDialog(
      venueId: contextData.venueId,
      venueName: contextData.venueName,
      repository: repository ?? VenueEventsRepository(),
      venueEvents: venueEvents,
      testCreatedBy: testCreatedBy,
      testStartDate: testStartDate,
      testEndDate: testEndDate,
    ),
  ).then((value) => value ?? false);
}

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.repository,
    this.venueEvents = const [],
    this.testCreatedBy,
    this.testStartDate,
    this.testEndDate,
  });

  final String venueId;
  final String venueName;
  final VenueEventsRepository repository;
  final List<EventModel> venueEvents;
  final String? testCreatedBy;
  final DateTime? testStartDate;
  final DateTime? testEndDate;

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
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
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final dateTimeError = validateEventDateTimeRange(
      startDate: _startDate,
      startTime: _startTimeController.text,
      endDate: _endDate,
      endTime: _endTimeController.text,
    );
    if (dateTimeError != null) {
      setState(() => _errorMessage = dateTimeError);
      return;
    }

    final featuredLimitError = FeaturedEventsLimit.validateAdd(
      wantsFeatured: _featured,
      venueEvents: widget.venueEvents,
    );
    if (featuredLimitError != null) {
      setState(() => _errorMessage = featuredLimitError);
      return;
    }

    final userId =
        widget.testCreatedBy ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _errorMessage = 'You must be signed in to create events.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.addEvent(
        venueId: widget.venueId,
        venueName: widget.venueName,
        title: _titleController.text,
        description: _descriptionController.text,
        startDateTime: combineEventDateAndTime(
          _startDate!,
          _startTimeController.text,
        ),
        endDateTime: combineEventDateAndTime(
          _endDate!,
          _endTimeController.text,
        ),
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
        _errorMessage = 'Could not save event. Please try again.';
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
                    'Add Event',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Create a new event for your venue.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  EventForm(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    startTimeController: _startTimeController,
                    endTimeController: _endTimeController,
                    startDate: _startDate,
                    endDate: _endDate,
                    isActive: _isActive,
                    featured: _featured,
                    enabled: !_saving,
                    onStartDateChanged: (value) =>
                        setState(() => _startDate = value),
                    onEndDateChanged: (value) => setState(() => _endDate = value),
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
                          key: const Key('create_event_submit_button'),
                          label: _saving ? 'Creating…' : 'Add Event',
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
