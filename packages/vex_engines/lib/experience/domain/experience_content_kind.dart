/// Categories of venue-published customer content owned by the Experience Engine.
enum ExperienceContentKind {
  drink,
  deal,
  event,

  /// Future-ready placeholders — structure only in Version 1.
  menu,
  happyHour,
  promotion,
  announcement,
  seasonalExperience,
}

/// Version 1 launch content kinds with runtime support.
const Set<ExperienceContentKind> experienceVersion1ContentKinds = {
  ExperienceContentKind.drink,
  ExperienceContentKind.deal,
  ExperienceContentKind.event,
};
