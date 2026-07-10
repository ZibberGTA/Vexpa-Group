/// Normalises venue contact links for web and mobile actions.
final class VenueContactUtils {
  VenueContactUtils._();

  static String? phoneDialUri(String? phone) {
    final cleaned = phone?.replaceAll(RegExp(r'[^\d+]+'), '').trim() ?? '';
    if (cleaned.isEmpty) return null;
    return 'tel:$cleaned';
  }

  static String? normaliseWebsiteUrl(String? website) {
    final trimmed = website?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  static String displayWebsite(String website) {
    return website
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }
}
