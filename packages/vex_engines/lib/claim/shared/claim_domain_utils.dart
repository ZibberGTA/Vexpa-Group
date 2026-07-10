/// Domain and contact normalisation helpers for claim scoring.
final class ClaimDomainUtils {
  ClaimDomainUtils._();

  static String digits(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  static String domainFromEmail(String value) {
    final parts = value.trim().toLowerCase().split('@');
    if (parts.length != 2) return '';
    return normaliseDomain(parts.last);
  }

  static String domainFromUrl(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final parsed = Uri.tryParse(
      trimmed.startsWith('http://') || trimmed.startsWith('https://')
          ? trimmed
          : 'https://$trimmed',
    );
    return normaliseDomain(parsed?.host ?? '');
  }

  static String normaliseDomain(String value) {
    return value.trim().toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  }
}
