import 'experience_content_kind.dart';

/// Documents future Experience Engine content modules not implemented in Version 1.
final class ExperienceFutureContent {
  ExperienceFutureContent._();

  static const plannedKinds = {
    ExperienceContentKind.menu,
    ExperienceContentKind.happyHour,
    ExperienceContentKind.promotion,
    ExperienceContentKind.announcement,
    ExperienceContentKind.seasonalExperience,
  };

  static bool isPlanned(ExperienceContentKind kind) =>
      plannedKinds.contains(kind);
}
