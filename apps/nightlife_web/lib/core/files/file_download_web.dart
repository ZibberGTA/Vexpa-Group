import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser download for generated spreadsheet bytes.
void downloadBytes(
  Uint8List bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  anchor.remove();
}
