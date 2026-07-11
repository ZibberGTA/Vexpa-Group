import 'package:vex_engines/experience/application/experience_deal_validator.dart';
import 'package:vex_engines/experience/shared/experience_deal_types.dart';

typedef DealTypes = ExperienceDealTypes;
typedef DealWeekdays = ExperienceDealWeekdays;

/// Form validation for deal modals.
class AddDealFormValidator {
  AddDealFormValidator._();

  static String? validateTitle(String? value) =>
      ExperienceDealValidator.validateTitle(value);

  static String? validateDealType(String? value) =>
      ExperienceDealValidator.validateDealType(value);

  static String? validateValue(String? value) =>
      ExperienceDealValidator.validateValue(value);

  static String? validateStartDate(DateTime? value) =>
      ExperienceDealValidator.validateStartDate(value);

  static String? validateEndDate(DateTime? start, DateTime? end) =>
      ExperienceDealValidator.validateEndDate(start, end);
}
