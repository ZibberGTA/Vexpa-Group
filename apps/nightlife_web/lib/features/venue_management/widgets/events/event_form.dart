import 'package:flutter/material.dart';
import 'package:vex_engines/experience/application/experience_event_validator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Shared event form fields for add modals.
class EventForm extends StatelessWidget {
  const EventForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.startTimeController,
    required this.endTimeController,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.featured,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onActiveChanged,
    required this.onFeaturedChanged,
    this.enabled = true,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool featured;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final bool enabled;

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime? initial,
    required ValueChanged<DateTime?> onChanged,
    DateTime? firstDate,
  }) async {
    if (!enabled) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPink,
              surface: AppColors.surfaceElevated,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) onChanged(picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: titleController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Event Title',
            hintText: 'Live DJ Night',
          ),
          validator: AddEventFormValidator.validateTitle,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: descriptionController,
          enabled: enabled,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'Short customer-facing explanation.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _DatePickerField(
                label: 'Start Date',
                valueLabel: _formatDate(startDate),
                enabled: enabled,
                onTap: () => _pickDate(
                  context,
                  initial: startDate,
                  onChanged: onStartDateChanged,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: startTimeController,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  hintText: '20:00',
                ),
                validator: AddEventFormValidator.validateStartTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _DatePickerField(
                label: 'End Date',
                valueLabel: _formatDate(endDate),
                enabled: enabled,
                onTap: () => _pickDate(
                  context,
                  initial: endDate ?? startDate,
                  firstDate: startDate,
                  onChanged: onEndDateChanged,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: endTimeController,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: '23:00',
                ),
                validator: AddEventFormValidator.validateEndTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Active / Published',
              style: TextStyle(color: AppColors.white),
            ),
            value: isActive,
            activeThumbColor: AppColors.primaryPink,
            onChanged: enabled ? onActiveChanged : null,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Featured', style: TextStyle(color: AppColors.white)),
            value: featured,
            activeThumbColor: AppColors.primaryPink,
            onChanged: enabled ? onFeaturedChanged : null,
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.valueLabel,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String valueLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    color: valueLabel == 'Select date'
                        ? AppColors.textSecondary
                        : AppColors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form validation for event modals.
class AddEventFormValidator {
  AddEventFormValidator._();

  static String? validateTitle(String? value) =>
      ExperienceEventValidator.validateTitle(value);

  static String? validateStartDate(DateTime? value) =>
      ExperienceEventValidator.validateStartDate(value);

  static String? validateStartTime(String? value) =>
      ExperienceEventValidator.validateStartTime(value);

  static String? validateEndTime(String? value) =>
      ExperienceEventValidator.validateEndTime(value);
}

/// Validates combined start/end date-time after form field validation.
String? validateEventDateTimeRange({
  required DateTime? startDate,
  required String startTime,
  required DateTime? endDate,
  required String endTime,
}) =>
    ExperienceEventValidator.validateDateTimeRange(
      startDate: startDate,
      startTime: startTime,
      endDate: endDate,
      endTime: endTime,
    );

DateTime combineEventDateAndTime(DateTime date, String time) =>
    ExperienceEventValidator.combineEventDateAndTime(date, time);
