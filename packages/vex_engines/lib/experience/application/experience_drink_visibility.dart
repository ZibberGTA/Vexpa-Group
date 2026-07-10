/// Public visibility rules for venue drinks on customer surfaces.
final class ExperienceDrinkVisibility {
  ExperienceDrinkVisibility._();

  static bool isPublicVisible({
    required bool isDeleted,
    required bool available,
  }) =>
      !isDeleted && available;
}
