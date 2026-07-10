/// Parses logo and banner URLs from Firestore venue documents.
///
/// The image engine denormalizes current branding to [logoUrl] and
/// [bannerImageUrl]. Legacy field names remain supported as fallbacks.
class VenueBrandingParser {
  VenueBrandingParser._();

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

  static String resolveBannerImageUrl(Map<String, dynamic> map) {
    return _resolveFromFields(map, bannerFieldPriority);
  }

  static String resolveLogoUrl(Map<String, dynamic> map) {
    return _resolveFromFields(map, logoFieldPriority);
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
}
