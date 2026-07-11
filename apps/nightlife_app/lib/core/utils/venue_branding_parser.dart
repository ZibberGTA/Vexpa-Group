import 'package:vex_engines/venue/shared/venue_image_field_parser.dart';

/// Parses logo and banner URLs from Firestore venue documents.
///
/// Delegates to the Venue Engine field parser for shared branding rules.
class VenueBrandingParser {
  VenueBrandingParser._();

  static const bannerFieldPriority = VenueImageFieldParser.bannerFieldPriority;
  static const logoFieldPriority = VenueImageFieldParser.logoFieldPriority;

  static String resolveBannerImageUrl(Map<String, dynamic> map) {
    return VenueImageFieldParser.resolveVenueBannerUrl(map);
  }

  static String resolveLogoUrl(Map<String, dynamic> map) {
    return VenueImageFieldParser.resolveVenueLogoUrl(map);
  }

  static String? parseImageField(dynamic value) {
    return VenueImageFieldParser.parseImageField(value);
  }

  static bool isValidImageUrl(String url) {
    return VenueImageFieldParser.isValidImageUrl(url);
  }
}
