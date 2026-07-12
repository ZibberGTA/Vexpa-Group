import 'experience_scheduling_utils.dart';

/// Validates venue event form input for management surfaces.
final class ExperienceEventValidator {
  ExperienceEventValidator._();

  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Event title is required.';
    }
    return null;
  }

  static String? validateStartDate(DateTime? value) {
    if (value == null) return 'Start date is required.';
    return null;
  }

  static String? validateStartTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Start time is required.';
    }
    if (!isValidTime(value)) return 'Enter a valid start time (HH:mm).';
    return null;
  }

  static String? validateEndTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'End time is required.';
    }
    if (!isValidTime(value)) return 'Enter a valid end time (HH:mm).';
    return null;
  }

  static bool isValidTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
    if (hour == null || minute == null) return false;
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  static String? validateDateTimeRange({
    required DateTime? startDate,
    required String startTime,
    required DateTime? endDate,
    required String endTime,
  }) {
    final startDateError = validateStartDate(startDate);
    if (startDateError != null) return startDateError;

    final startTimeError = validateStartTime(startTime);
    if (startTimeError != null) return startTimeError;

    final endTimeError = validateEndTime(endTime);
    if (endTimeError != null) return endTimeError;

    if (endDate == null) return 'End date is required.';

    final start = combineEventDateAndTime(startDate!, startTime);
    final end = combineEventDateAndTime(endDate, endTime);
    if (!end.isAfter(start)) {
      return 'End date/time must be after start date/time.';
    }
    return null;
  }

  static DateTime combineEventDateAndTime(DateTime date, String time) =>
      ExperienceSchedulingUtils.combineDateAndTime(date, time);
}
