/// Parses Firebase Storage download URLs into object paths.
///
/// Supports:
/// - `https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?...`
/// - `https://{bucket}.firebasestorage.app/o/{path}?...`
String? parseFirebaseStoragePathFromDownloadUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  try {
    final uri = Uri.parse(trimmed);
    final host = uri.host.toLowerCase();
    final isFirebaseHost = host.contains('firebasestorage.googleapis.com') ||
        host.endsWith('.firebasestorage.app');
    if (!isFirebaseHost) return null;

    final match = RegExp(r'/o/([^?#]+)').firstMatch(uri.path);
    if (match == null) return null;

    final encodedPath = match.group(1);
    if (encodedPath == null || encodedPath.isEmpty) return null;

    return Uri.decodeComponent(encodedPath.replaceAll('+', ' '));
  } catch (_) {
    return null;
  }
}
