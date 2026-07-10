import '../../../core/utils/venue_branding_parser.dart';
import '../../home/models/event_model.dart';
import '../models/venue_details_model.dart';
import '../models/venue_media_model.dart';

/// Resolves display URLs for venue-owned media with legacy fallbacks.
///
/// Logo and banner prefer denormalized venue document fields (updated by the
/// image engine on upload). Media subcollection values are fallback only.
class VenueImageResolver {
  VenueImageResolver._();

  static String resolveLogo({
    required VenueDetailsModel venue,
    VenueMediaModel? currentLogoMedia,
  }) {
    final docLogo = venue.logoUrl.trim();
    if (docLogo.isNotEmpty) return docLogo;

    if (currentLogoMedia != null &&
        currentLogoMedia.isCurrent &&
        currentLogoMedia.imageUrl.trim().isNotEmpty) {
      return currentLogoMedia.imageUrl.trim();
    }

    return '';
  }

  static String resolveBanner({
    required VenueDetailsModel venue,
    VenueMediaModel? currentBannerMedia,
  }) {
    final docBanner = venue.coverImageUrl.trim();
    if (docBanner.isNotEmpty) return docBanner;

    if (currentBannerMedia != null &&
        currentBannerMedia.isCurrent &&
        currentBannerMedia.imageUrl.trim().isNotEmpty) {
      return currentBannerMedia.imageUrl.trim();
    }

    return '';
  }

  static String resolveLogoFromMap(Map<String, dynamic> map) {
    return VenueBrandingParser.resolveLogoUrl(map);
  }

  static String resolveBannerFromMap(Map<String, dynamic> map) {
    return VenueBrandingParser.resolveBannerImageUrl(map);
  }

  static List<String> resolveGalleryUrls({
    required VenueDetailsModel venue,
    required List<VenueMediaModel> galleryMedia,
  }) {
    if (galleryMedia.isNotEmpty) {
      return galleryMedia
          .where((item) => item.visible && item.imageUrl.trim().isNotEmpty)
          .map((item) => item.imageUrl.trim())
          .toList();
    }

    return venue.galleryImageUrls
        .where((url) => url.trim().isNotEmpty)
        .map((url) => url.trim())
        .toList();
  }

  static String? dealImageUrl({
    required String dealId,
    required List<VenueMediaModel> dealMedia,
  }) {
    for (final item in dealMedia) {
      if (!item.visible) continue;
      if (item.linkedDealId == dealId && item.imageUrl.trim().isNotEmpty) {
        return item.imageUrl.trim();
      }
    }
    return null;
  }

  static String resolveEventImage({
    required EventModel event,
    required List<VenueMediaModel> eventMedia,
  }) {
    for (final item in eventMedia) {
      if (!item.visible) continue;
      if (item.linkedEventId == event.id && item.imageUrl.trim().isNotEmpty) {
        return item.imageUrl.trim();
      }
    }

    return event.imageUrl.trim();
  }
}
