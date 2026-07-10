import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Picks a single image file from the user's device.
Future<Uint8List?> pickVenueImageBytes() async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;
  return result.files.single.bytes;
}

/// Picks up to [limit] image files from the user's device.
Future<List<({Uint8List bytes, String fileName})>> pickVenueImageFiles({
  int limit = 10,
}) async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    allowMultiple: limit > 1,
    withData: true,
  );

  if (result == null || result.files.isEmpty) return const [];

  final picked = <({Uint8List bytes, String fileName})>[];
  for (final file in result.files.take(limit)) {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) continue;
    picked.add((bytes: bytes, fileName: file.name));
  }
  return picked;
}

MemoryImage? memoryImageFromBytes(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  return MemoryImage(bytes);
}
