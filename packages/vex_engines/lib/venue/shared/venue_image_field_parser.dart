import '../shared/image_position_metadata.dart';

/// Parses logo and banner URLs from venue document maps.
///
/// Mirrors the mobile app's branding field priority: current branding lives in
/// `logoUrl` and `bannerImageUrl`, with legacy field names as fallbacks.
final class VenueImageFieldParser {
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

  static String resolveVenueBannerUrl(Map<String, dynamic> map) {
    return _resolveFromFields(map, bannerFieldPriority);
  }

  static String resolveVenueLogoUrl(Map<String, dynamic> map) {
    return _resolveFromFields(map, logoFieldPriority);
  }

  static String resolveBannerImageUrl(Map<String, dynamic> map) {
    return resolveVenueBannerUrl(map);
  }

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
