import 'experience_deal_validator.dart';
import 'experience_drink_validator.dart';
import 'experience_event_validator.dart';
import 'experience_scheduling_utils.dart';

/// Unified validation surface for venue-published content.
final class VenueContentValidationService {
  const VenueContentValidationService();

  // Drink validation
  String? validateDrinkName(String? value) =>
      ExperienceDrinkValidator.validateName(value);

  String? validateDrinkCategory(
    String? value, {
    required bool Function(String category) isAllowed,
  }) =>
      ExperienceDrinkValidator.validateCategory(value, isAllowed: isAllowed);

  String? validateDrinkPrice(String? value) =>
      ExperienceDrinkValidator.validatePrice(value);

  double? parseNormalizedPrice(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll('£', '').replaceAll(',', '');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  // Deal validation
  String? validateDealTitle(String? value) =>
      ExperienceDealValidator.validateTitle(value);

  String? validateDealType(String? value) =>
      ExperienceDealValidator.validateDealType(value);

  String? validateDealValue(String? value) =>
      ExperienceDealValidator.validateValue(value);

  String? validateDealDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
  }) {
    final startError = ExperienceDealValidator.validateStartDate(startDate);
    if (startError != null) return startError;
    return ExperienceDealValidator.validateEndDate(startDate, endDate);
  }

  String? validateDealEndAfterStart({
    required DateTime? startDateTime,
    required DateTime? endDate,
    required String endTime,
  }) {
    if (startDateTime == null || endDate == null) return null;
    final end = ExperienceSchedulingUtils.combineDateAndTime(endDate, endTime);
    if (!end.isAfter(startDateTime)) {
      return 'End date/time must be after start date/time.';
    }
    return null;
  }

  // Event validation
  String? validateEventTitle(String? value) =>
      ExperienceEventValidator.validateTitle(value);

  String? validateEventStartDate(DateTime? value) =>
      ExperienceEventValidator.validateStartDate(value);

  String? validateEventStartTime(String? value) =>
      ExperienceEventValidator.validateStartTime(value);

  String? validateEventEndTime(String? value) =>
      ExperienceEventValidator.validateEndTime(value);

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
}
