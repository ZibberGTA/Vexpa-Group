import 'package:vex_engines/experience/application/experience_drink_validator.dart';
import 'package:vex_engines/experience/shared/experience_drink_categories.dart';

typedef DrinkCategories = ExperienceDrinkCategories;

/// Validates add-drink form input.
class AddDrinkFormValidator {
  AddDrinkFormValidator._();

  static String? validateName(String? value) =>
      ExperienceDrinkValidator.validateName(value);

  static String? validateCategory(String? value) =>
      ExperienceDrinkValidator.validateCategory(
        value,
        isAllowed: DrinkCategories.isAllowed,
      );

  static String? validatePrice(String? value) =>
      ExperienceDrinkValidator.validatePrice(value);
}
