import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../models/deal_types.dart';

/// Shared deal form fields for add and edit modals.
class DealForm extends StatelessWidget {
  const DealForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.valueController,
    required this.startTimeController,
    required this.endTimeController,
    required this.selectedDealType,
    required this.startDate,
    required this.endDate,
    required this.availableDays,
    required this.isActive,
    required this.featured,
    required this.onDealTypeChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onAvailableDayToggled,
    required this.onActiveChanged,
    required this.onFeaturedChanged,
    this.enabled = true,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController valueController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final String? selectedDealType;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> availableDays;
  final bool isActive;
  final bool featured;
  final ValueChanged<String?> onDealTypeChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final void Function(String day, bool selected) onAvailableDayToggled;
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
            labelText: 'Deal Title',
            hintText: '2-for-1 Cocktails',
          ),
          validator: AddDealFormValidator.validateTitle,
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
        DropdownButtonFormField<String>(
          value: selectedDealType,
          decoration: const InputDecoration(labelText: 'Deal Type'),
          items: DealTypes.all
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(DealTypes.displayName(type)),
                ),
              )
              .toList(),
          onChanged: enabled ? onDealTypeChanged : null,
          validator: AddDealFormValidator.validateDealType,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: valueController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Value (optional)',
            hintText: '20, £5, 2-for-1',
          ),
          validator: AddDealFormValidator.validateValue,
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
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Available Days (optional)',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.95),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final day in DealWeekdays.all)
              FilterChip(
                label: Text(day.substring(0, 3)),
                selected: availableDays.contains(day),
                onSelected: enabled
                    ? (selected) => onAvailableDayToggled(day, selected)
                    : null,
                selectedColor: AppColors.primaryPink.withValues(alpha: 0.28),
                checkmarkColor: AppColors.white,
                labelStyle: TextStyle(
                  color: availableDays.contains(day)
                      ? AppColors.white
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: startTimeController,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'Start Time (optional)',
                  hintText: '17:00',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: endTimeController,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'End Time (optional)',
                  hintText: '22:00',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active', style: TextStyle(color: AppColors.white)),
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

/// Validates start/end dates after form field validation.
String? validateDealDateRange(DateTime? start, DateTime? end) {
  final startError = AddDealFormValidator.validateStartDate(start);
  if (startError != null) return startError;
  return AddDealFormValidator.validateEndDate(start, end);
}
