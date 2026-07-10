/// Shared venue profile field options aligned with the Vexda mobile app.
final class VenueProfileConstants {
  VenueProfileConstants._();

  static const int maxFeatureTags = 3;

  static const List<String> categories = ['Bar', 'Club', 'Pub'];

  /// Crowd levels accepted across owner tools, search, and public surfaces.
  static const List<VenueCrowdLevelOption> crowdLevels = [
    VenueCrowdLevelOption(value: 'quiet', label: 'Quiet'),
    VenueCrowdLevelOption(value: 'steady', label: 'Steady'),
    VenueCrowdLevelOption(value: 'moderate', label: 'Moderate'),
    VenueCrowdLevelOption(value: 'medium', label: 'Medium'),
    VenueCrowdLevelOption(value: 'busy', label: 'Busy'),
    VenueCrowdLevelOption(value: 'packed', label: 'Packed'),
  ];

  static const Map<String, String> featureTagOptions = {
    'liveMusic': 'Live Music',
    'dj': 'DJ',
    'sports': 'Sports',
    'karaoke': 'Karaoke',
    'quizNight': 'Quiz Night',
    'danceFloor': 'Dance Floor',
    'foodServed': 'Food Served',
    'outdoorSeating': 'Outdoor',
  };

  static const List<String> openingDayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const Map<String, String> openingDayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  static int crowdScoreForLevel(String level) {
    switch (level.toLowerCase()) {
      case 'quiet':
        return 1;
      case 'steady':
        return 2;
      case 'moderate':
      case 'medium':
        return 3;
      case 'busy':
        return 4;
      case 'packed':
        return 5;
      default:
        return 1;
    }
  }
}

final class VenueCrowdLevelOption {
  const VenueCrowdLevelOption({required this.value, required this.label});

  final String value;
  final String label;
}
