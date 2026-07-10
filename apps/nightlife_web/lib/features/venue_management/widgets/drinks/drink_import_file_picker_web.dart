import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import 'drink_import_file_picker_exception.dart';

const _allowedExtensions = {'xlsx', 'xls', 'csv'};

/// Opens the browser file picker and reads spreadsheet bytes on Flutter Web.
Future<DrinkImportPickedFile?> pickDrinkImportSpreadsheet() async {
  final completer = Completer<DrinkImportPickedFile?>();
  var completed = false;

  void complete(DrinkImportPickedFile? value) {
    if (completed) return;
    completed = true;
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  void completeError(Object error) {
    if (completed) return;
    completed = true;
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
  }

  final input = HTMLInputElement()
    ..type = 'file'
    ..accept =
        '.xlsx,.xls,.csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,text/csv'
    ..multiple = false
    ..style.display = 'none';

  void cleanup() {
    input.remove();
  }

  void handleCancel(Event event) {
    window.removeEventListener('focus', handleCancel.toJS);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!completed) {
        complete(null);
        cleanup();
      }
    });
  }

  void handleChange(Event event) {
    window.removeEventListener('focus', handleCancel.toJS);

    final files = input.files;
    if (files == null || files.length == 0) {
      complete(null);
      cleanup();
      return;
    }

    final file = files.item(0);
    if (file == null) {
      complete(null);
      cleanup();
      return;
    }

    final extension = file.name.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      completeError(UnsupportedDrinkImportFileTypeException(file.name));
      cleanup();
      return;
    }

    final reader = FileReader();
    reader.onLoadEnd.listen((_) {
      try {
        final buffer = (reader.result as JSArrayBuffer?)?.toDart;
        if (buffer == null) {
          completeError(
            DrinkImportFilePickerException('Could not read the selected file.'),
          );
          return;
        }

        complete((
          bytes: buffer.asUint8List(),
          filename: file.name,
        ));
      } catch (_) {
        completeError(
          DrinkImportFilePickerException('Could not read the selected file.'),
        );
      } finally {
        cleanup();
      }
    });
    reader.readAsArrayBuffer(file);
  }

  input.addEventListener('change', handleChange.toJS);
  document.body?.append(input);
  window.addEventListener('focus', handleCancel.toJS);
  input.click();

  return completer.future;
}
