import '../models/image_position_metadata.dart';

/// Parses logo and banner URLs from Firestore venue documents.
///
/// Mirrors the mobile app's `VenueBrandingParser`: the image engine writes
/// current branding to `logoUrl` and `bannerImageUrl`, while legacy field names
/// remain supported as fallbacks.
class VenueImageFieldParser {
  VenueImageFieldParser._();

  static const bannerFieldPriority = <String>[
    'bannerImageUrl',
    'bannerUrl',
    'bannerImage',
    'coverImageUrl',
    'headerImageUrl',
    'imageUrl',
  ];

  static const logoFieldPriority = <String>[
    'logoUrl',
    'logoImageUrl',
    'venueLogoUrl',
  ];

  /// Resolves the venue banner URL using the mobile app field priority.
  static String resolveVenueBannerUrl(Map<String, dynamic> map) {
    return _resolveFromFields(map, bannerFieldPriority);
  }

  /// Resolves the venue logo URL using the mobile app field priority.
  static String resolveVenueLogoUrl(Map<String, dynamic> map) {
    return _resolveFromFields(map, logoFieldPriority);
  }

  /// Backwards-compatible alias for existing callers.
  static String resolveBannerImageUrl(Map<String, dynamic> map) {
    return resolveVenueBannerUrl(map);
  }

  /// Backwards-compatible alias for existing callers.
  static String resolveLogoUrl(Map<String, dynamic> map) {
    return resolveVenueLogoUrl(map);
  }

  static String _resolveFromFields(
    Map<String, dynamic> map,
    List<String> fieldNames,
  ) {
    for (final field in fieldNames) {
      if (!map.containsKey(field)) continue;
      final resolved = parseImageField(map[field]);
      if (resolved != null) return resolved;
    }
    return '';
  }

  /// Parses a Firestore image field value into a usable network URL.
  static String? parseImageField(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final nestedKey in ['url', 'downloadUrl', 'uri', 'src']) {
        final nested = parseImageField(map[nestedKey]);
        if (nested != null) return nested;
      }
      return null;
    }

    final trimmed = value.toString().trim();
    if (trimmed.isEmpty || trimmed == 'null') return null;
    return isValidImageUrl(trimmed) ? trimmed : null;
  }

  /// Returns true when [url] is a potentially loadable http(s) image URL.
  static bool isValidImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  static bool isRenderableImageUrl(String? url) {
    final trimmed = url?.trim();
    return trimmed != null && trimmed.isNotEmpty && isValidImageUrl(trimmed);
  }

  static ImagePositionMetadata? resolveBannerImagePosition(
    Map<String, dynamic> map,
  ) {
    return _resolveImagePosition(map, 'bannerImagePosition');
  }

  static ImagePositionMetadata? resolveLogoImagePosition(
    Map<String, dynamic> map,
  ) {
    return _resolveImagePosition(map, 'logoImagePosition');
  }

  static Map<String, ImagePositionMetadata> resolveGalleryImagePositions(
    Map<String, dynamic> map,
  ) {
    final raw = map['galleryImagePositions'];
    if (raw is! Map) return const {};

    final positions = <String, ImagePositionMetadata>{};
    raw.forEach((key, value) {
      if (value is Map) {
        positions[key.toString()] = ImagePositionMetadata.fromMap(
          Map<String, dynamic>.from(value),
        );
      }
    });
    return positions;
  }

  static ImagePositionMetadata? _resolveImagePosition(
    Map<String, dynamic> map,
    String field,
  ) {
    final raw = map[field];
    if (raw is Map) {
      return ImagePositionMetadata.fromMap(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
