import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Picks a single claim evidence document from the user's device.
Future<({Uint8List bytes, String fileName})?> pickClaimEvidenceFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    allowMultiple: false,
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) return null;
  return (bytes: bytes, fileName: file.name);
}
