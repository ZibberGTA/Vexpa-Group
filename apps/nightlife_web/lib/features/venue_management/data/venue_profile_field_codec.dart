import '../../venues/models/venue_model.dart';
import 'venue_profile_constants.dart';

/// Encodes and decodes venue profile fields for Firestore writes.
class VenueProfileFieldCodec {
  VenueProfileFieldCodec._();

  static bool isAgeRestrictedVenue(
    VenueModel venue,
    Map<String, dynamic>? rawDocument,
  ) {
    final features = rawDocument?['venueFeatures'];
    if (features is Map) {
      final map = Map<String, dynamic>.from(features);
      if (map['age18'] == true || map['age21'] == true) return true;
    }

    for (final tag in venue.featureTags) {
      final lower = tag.toLowerCase();
      if (lower.contains('18') || lower.contains('21')) return true;
    }
    return false;
  }

  static Set<String> selectedFeatureTagKeys(
    VenueModel venue,
    Map<String, dynamic>? rawDocument,
  ) {
    final selected = <String>{};
    final labelToKey = {
      for (final entry in VenueProfileConstants.featureTagOptions.entries)
        entry.value.toLowerCase(): entry.key,
    };

    for (final tag in venue.featureTags) {
      final key = labelToKey[tag.trim().toLowerCase()];
      if (key != null) selected.add(key);
    }

    final features = rawDocument?['venueFeatures'];
    if (features is Map) {
      final map = Map<String, dynamic>.from(features);
      for (final entry in VenueProfileConstants.featureTagOptions.entries) {
        if (map[entry.key] == true) selected.add(entry.key);
      }
    }

    return selected;
  }

  static List<String> displayFeatureTags(VenueModel venue) {
    final tags = venue.featureTags.isNotEmpty ? venue.featureTags : venue.features;
    return tags.take(VenueProfileConstants.maxFeatureTags).toList();
  }

  static Map<String, dynamic> buildFeatureTagsUpdate({
    required Set<String> selectedKeys,
    required bool ageRestricted,
  }) {
    final trimmedKeys = selectedKeys
        .where(VenueProfileConstants.featureTagOptions.containsKey)
        .take(VenueProfileConstants.maxFeatureTags)
        .toList();

    final labels = trimmedKeys
        .map((key) => VenueProfileConstants.featureTagOptions[key]!)
        .toList();

    final venueFeatures = <String, dynamic>{
      for (final key in VenueProfileConstants.featureTagOptions.keys)
        key: trimmedKeys.contains(key),
      'age18': ageRestricted,
      'age21': false,
    };

    return {
      'featureTags': labels,
      'venueFeatures': venueFeatures,
    };
  }

  static List<String> buildSearchTerms({
    required String name,
    required String description,
    required String address,
    required String category,
    required String crowdLevel,
  }) {
    return [
      name,
      description,
      address,
      category,
      crowdLevel,
      ...name.split(' '),
      ...description.split(' '),
      ...address.split(' '),
      ...category.split(' '),
    ]
        .map((term) => term.trim().toLowerCase())
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();
  }

  static String normaliseWebsite(String value) {
    var website = value.trim();
    if (website.isEmpty) return '';
    if (!website.startsWith('http://') && !website.startsWith('https://')) {
      website = 'https://$website';
    }
    return website;
  }

  static String? validateWebsite(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final normalised = normaliseWebsite(trimmed);
    final uri = Uri.tryParse(normalised);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return 'Enter a valid website URL';
    }
    if (!uri.host.contains('.') && uri.host != 'localhost') {
      return 'Enter a valid website URL';
    }
    return null;
  }

  static String normaliseTimeInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 3) {
      return '0${digits[0]}:${digits.substring(1)}';
    }
    if (digits.length == 4) {
      return '${digits.substring(0, 2)}:${digits.substring(2)}';
    }
    return trimmed;
  }

  static bool isValidTime(String value) {
    final normalised = normaliseTimeInput(value);
    return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(normalised);
  }

  static Map<String, Map<String, dynamic>> parseOpeningHours(
    Map<String, dynamic> openingHours,
  ) {
    final result = <String, Map<String, dynamic>>{};

    for (final day in VenueProfileConstants.openingDayKeys) {
      final rawDay = openingHours[day];
      final dayData = rawDay is Map
          ? Map<String, dynamic>.from(rawDay)
          : const <String, dynamic>{};

      result[day] = {
        'closed': dayData['closed'] == true || dayData['isClosed'] == true,
        'open': normaliseTimeInput((dayData['open'] ?? '12:00').toString()),
        'close': normaliseTimeInput((dayData['close'] ?? '23:00').toString()),
      };
    }

    return result;
  }

  static Map<String, Map<String, dynamic>> buildOpeningHoursMap(
    Map<String, Map<String, dynamic>> draft,
  ) {
    final result = <String, Map<String, dynamic>>{};

    for (final day in VenueProfileConstants.openingDayKeys) {
      final dayData = draft[day] ?? const {};
      final isClosed = dayData['closed'] == true;
      result[day] = {
        'closed': isClosed,
        'open': normaliseTimeInput((dayData['open'] ?? '').toString()),
        'close': normaliseTimeInput((dayData['close'] ?? '').toString()),
      };
    }

    return result;
  }

  static String? validateOpeningHours(Map<String, Map<String, dynamic>> draft) {
    for (final day in VenueProfileConstants.openingDayKeys) {
      final dayData = draft[day] ?? const {};
      if (dayData['closed'] == true) continue;

      final label = VenueProfileConstants.openingDayLabels[day] ?? day;
      final open = normaliseTimeInput((dayData['open'] ?? '').toString());
      final close = normaliseTimeInput((dayData['close'] ?? '').toString());

      if (!isValidTime(open) || !isValidTime(close)) {
        return '$label opening times must use 24-hour format, for example 18:00 or 02:00.';
      }
    }
    return null;
  }
}
