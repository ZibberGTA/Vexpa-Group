import 'package:vex_engines/venue/domain/venue_profile_field_codec.dart'
    as engine;

import '../../venues/models/venue_model.dart';

export 'package:vex_engines/venue/domain/venue_profile_constants.dart';

/// Encodes and decodes venue profile fields for Firestore writes.
class VenueProfileFieldCodec {
  VenueProfileFieldCodec._();

  static bool isAgeRestrictedVenue(
    VenueModel venue,
    Map<String, dynamic>? rawDocument,
  ) {
    return engine.VenueProfileFieldCodec.isAgeRestrictedVenue(
      featureTags: venue.featureTags,
      rawDocument: rawDocument,
    );
  }

  static Set<String> selectedFeatureTagKeys(
    VenueModel venue,
    Map<String, dynamic>? rawDocument,
  ) {
    return engine.VenueProfileFieldCodec.selectedFeatureTagKeys(
      featureTags: venue.featureTags,
      rawDocument: rawDocument,
    );
  }

  static List<String> displayFeatureTags(VenueModel venue) {
    return engine.VenueProfileFieldCodec.displayFeatureTags(
      featureTags: venue.featureTags,
      features: venue.features,
    );
  }

  static Map<String, dynamic> buildFeatureTagsUpdate({
    required Set<String> selectedKeys,
    required bool ageRestricted,
  }) {
    return engine.VenueProfileFieldCodec.buildFeatureTagsUpdate(
      selectedKeys: selectedKeys,
      ageRestricted: ageRestricted,
    );
  }

  static List<String> buildSearchTerms({
    required String name,
    required String description,
    required String address,
    required String category,
    required String crowdLevel,
  }) {
    return engine.VenueProfileFieldCodec.buildSearchTerms(
      name: name,
      description: description,
      address: address,
      category: category,
      crowdLevel: crowdLevel,
    );
  }

  static String normaliseWebsite(String value) {
    return engine.VenueProfileFieldCodec.normaliseWebsite(value);
  }

  static String? validateWebsite(String value) {
    return engine.VenueProfileFieldCodec.validateWebsite(value);
  }

  static String? validateEmail(String value) {
    return engine.VenueProfileFieldCodec.validateEmail(value);
  }

  static String normaliseTimeInput(String value) {
    return engine.VenueProfileFieldCodec.normaliseTimeInput(value);
  }

  static bool isValidTime(String value) {
    return engine.VenueProfileFieldCodec.isValidTime(value);
  }

  static Map<String, Map<String, dynamic>> parseOpeningHours(
    Map<String, dynamic> openingHours,
  ) {
    return engine.VenueProfileFieldCodec.parseOpeningHours(openingHours);
  }

  static Map<String, Map<String, dynamic>> buildOpeningHoursMap(
    Map<String, Map<String, dynamic>> draft,
  ) {
    return engine.VenueProfileFieldCodec.buildOpeningHoursMap(draft);
  }

  static String? validateOpeningHours(
    Map<String, Map<String, dynamic>> draft,
  ) {
    return engine.VenueProfileFieldCodec.validateOpeningHours(draft);
  }
}
