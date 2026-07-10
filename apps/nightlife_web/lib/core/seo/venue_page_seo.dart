import 'venue_page_seo_impl_stub.dart'
    if (dart.library.html) 'venue_page_seo_impl_web.dart' as seo_impl;

/// Applies venue-specific SEO metadata on supported platforms.
abstract final class VenuePageSeo {
  static void apply({
    required String venueName,
    required String description,
    required String canonicalPath,
    String? imageUrl,
    String? address,
    String? phone,
    String? website,
    double? rating,
    double? latitude,
    double? longitude,
  }) {
    seo_impl.applyVenuePageSeo(
      venueName: venueName,
      description: description,
      canonicalPath: canonicalPath,
      imageUrl: imageUrl,
      address: address,
      phone: phone,
      website: website,
      rating: rating,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static void reset() {
    seo_impl.resetVenuePageSeo();
  }
}
