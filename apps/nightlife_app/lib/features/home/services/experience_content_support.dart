import 'package:vex_engines/experience/application/experience_drink_import_validator.dart';
import 'package:vex_engines/experience/application/experience_owner_write_service.dart';

/// Mobile adapter facades for Experience Engine venue content services.
final class MobileExperienceContentSupport {
  MobileExperienceContentSupport._();

  static const ownerWrite = ExperienceOwnerWriteService();
  static const drinkImport = ExperienceDrinkImportValidator();
}
