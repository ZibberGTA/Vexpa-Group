/// Errors surfaced when picking a drinks import spreadsheet fails.
class DrinkImportFilePickerException implements Exception {
  DrinkImportFilePickerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when the selected file extension is not supported.
class UnsupportedDrinkImportFileTypeException extends DrinkImportFilePickerException {
  UnsupportedDrinkImportFileTypeException(String filename)
      : super(
          'Unsupported file type for "$filename". Upload .xlsx, .xls or .csv.',
        );
}

/// A picked spreadsheet ready for parsing.
typedef DrinkImportPickedFile = ({List<int> bytes, String filename});
