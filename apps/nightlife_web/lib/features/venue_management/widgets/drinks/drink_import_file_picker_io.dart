import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import 'drink_import_file_picker_exception.dart';

/// Opens the native file picker on IO platforms (desktop/mobile tests).
Future<DrinkImportPickedFile?> pickDrinkImportSpreadsheet() async {
  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      throw DrinkImportFilePickerException('Could not read the selected file.');
    }

    final extension = file.name.split('.').last.toLowerCase();
    if (!const {'xlsx', 'xls', 'csv'}.contains(extension)) {
      throw UnsupportedDrinkImportFileTypeException(file.name);
    }

    return (bytes: bytes, filename: file.name);
  } on DrinkImportFilePickerException {
    rethrow;
  } on MissingPluginException {
    throw DrinkImportFilePickerException(
      'File upload is unavailable on this platform. Restart the app after adding file_picker.',
    );
  } on PlatformException {
    throw DrinkImportFilePickerException('Could not open the file picker.');
  }
}
