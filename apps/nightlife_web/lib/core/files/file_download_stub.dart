import 'dart:typed_data';

/// No-op download for tests and non-web platforms.
void downloadBytes(
  Uint8List bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) {}
