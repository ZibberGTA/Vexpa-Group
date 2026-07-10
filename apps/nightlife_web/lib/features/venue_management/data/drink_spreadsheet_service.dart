import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../../venue/data/models/drink_model.dart';
import '../models/drink_categories.dart';
import '../models/drink_import_row.dart';

/// Spreadsheet parsing, validation, template generation and export for drinks.
class DrinkSpreadsheetService {
  DrinkSpreadsheetService._();

  static const requiredColumns = [
    'name',
    'category',
    'price',
    'available',
    'featured',
  ];

  static const templateFilename = 'vexda-drinks-import-template.xlsx';
  static const templateMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  static DrinkImportParseResult parseFile({
    required Uint8List bytes,
    required String filename,
    required Set<String> existingDrinkNames,
  }) {
    try {
      final extension = _extension(filename);
      final rawRows = switch (extension) {
        'csv' => _parseCsv(bytes),
        'xlsx' || 'xls' => _parseSpreadsheet(bytes),
        _ => null,
      };

      if (rawRows == null) {
        return const DrinkImportParseResult(
          rows: [],
          fileError: 'Unsupported file type. Upload .xlsx, .xls or .csv.',
        );
      }

      if (rawRows.isEmpty) {
        return const DrinkImportParseResult(
          rows: [],
          fileError: 'The uploaded file is empty.',
        );
      }

      final headerRow = rawRows.first;
      final columnMap = _mapColumns(headerRow);
      if (columnMap == null) {
        return const DrinkImportParseResult(
          rows: [],
          fileError:
              'Missing required columns. The file must include name, category, price, available and featured.',
        );
      }

      final parsedRows = <DrinkImportRow>[];
      for (var i = 1; i < rawRows.length; i++) {
        final cells = rawRows[i];
        if (_isEmptyDataRow(cells)) continue;

        parsedRows.add(
          _validateRow(
            rowNumber: i + 1,
            cells: cells,
            columnMap: columnMap,
            existingDrinkNames: existingDrinkNames,
          ),
        );
      }

      if (parsedRows.isEmpty) {
        return const DrinkImportParseResult(
          rows: [],
          fileError: 'No drink rows were found in the uploaded file.',
        );
      }

      return DrinkImportParseResult(rows: parsedRows);
    } catch (_) {
      return const DrinkImportParseResult(
        rows: [],
        fileError: 'Could not read the uploaded file. Check the format and try again.',
      );
    }
  }

  static Uint8List buildTemplateBytes() {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? excel.sheets.keys.first;
    if (defaultSheet != 'Drinks') {
      excel.rename(defaultSheet, 'Drinks');
    }
    final sheet = excel['Drinks'];

    sheet.appendRow(requiredColumns.map((value) => TextCellValue(value)).toList());
    sheet.appendRow([
      TextCellValue('Espresso Martini'),
      TextCellValue('Cocktails'),
      TextCellValue('9.50'),
      TextCellValue('true'),
      TextCellValue('false'),
    ]);
    sheet.appendRow([
      TextCellValue('Peroni Pint'),
      TextCellValue('Beer'),
      TextCellValue('6.20'),
      TextCellValue('true'),
      TextCellValue('false'),
    ]);

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Could not generate drinks import template.');
    }
    return Uint8List.fromList(encoded);
  }

  static Uint8List exportDrinksBytes(List<DrinkModel> drinks) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? excel.sheets.keys.first;
    if (defaultSheet != 'Drinks') {
      excel.rename(defaultSheet, 'Drinks');
    }
    final sheet = excel['Drinks'];

    sheet.appendRow(requiredColumns.map((value) => TextCellValue(value)).toList());

    for (final drink in drinks) {
      sheet.appendRow([
        TextCellValue(drink.name),
        TextCellValue(DrinkCategories.displayName(drink.category)),
        TextCellValue(drink.exportPriceValue),
        TextCellValue(drink.available.toString()),
        TextCellValue(drink.featured.toString()),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Could not export drinks spreadsheet.');
    }
    return Uint8List.fromList(encoded);
  }

  static String exportFilename(String venueName, DateTime date) {
    final slug = venueName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final safeSlug = slug.isEmpty ? 'venue' : slug;
    final stamp =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'vexda-drinks-$safeSlug-$stamp.xlsx';
  }

  static List<DrinkImportCommitRow> rowsToCommit({
    required List<DrinkImportRow> rows,
    required bool includeDuplicates,
  }) {
    return rows
        .where((row) {
          if (row.isBlocking) return false;
          if (row.isDuplicateWarning) return includeDuplicates;
          return true;
        })
        .map(
          (row) => DrinkImportCommitRow(
            name: row.name.trim(),
            category: row.category.trim(),
            price: row.price,
            available: row.available,
            featured: row.featured,
          ),
        )
        .toList();
  }

  static List<List<String>> _parseCsv(Uint8List bytes) {
    final content = utf8.decode(bytes, allowMalformed: true);
    final parsed = csv.decode(content);
    return parsed
        .map(
          (row) => row.map((cell) => cell?.toString().trim() ?? '').toList(),
        )
        .toList();
  }

  static List<List<String>> _parseSpreadsheet(Uint8List bytes) {
    final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
    if (decoder.tables.isEmpty) return const [];

    final table = decoder.tables.values.first;
    return table.rows
        .map(
          (row) => row
              .map((cell) => cell?.toString().trim() ?? '')
              .toList(),
        )
        .toList();
  }

  static Map<String, int>? _mapColumns(List<String> headerRow) {
    final normalized = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final key = headerRow[i].trim().toLowerCase();
      if (key.isEmpty) continue;
      normalized[key] = i;
    }

    final columnMap = <String, int>{};
    for (final column in requiredColumns) {
      final index = normalized[column];
      if (index == null) return null;
      columnMap[column] = index;
    }
    return columnMap;
  }

  static bool _isEmptyDataRow(List<String> cells) {
    return cells.every((cell) => cell.trim().isEmpty);
  }

  static DrinkImportRow _validateRow({
    required int rowNumber,
    required List<String> cells,
    required Map<String, int> columnMap,
    required Set<String> existingDrinkNames,
  }) {
    final name = _cellValue(cells, columnMap['name']!);
    final category = _cellValue(cells, columnMap['category']!);
    final priceRaw = _cellValue(cells, columnMap['price']!);
    final availableRaw = _cellValue(cells, columnMap['available']!);
    final featuredRaw = _cellValue(cells, columnMap['featured']!);

    final parsedAvailable = parseOptionalBoolean(availableRaw);
    final parsedFeatured = parseOptionalBoolean(featuredRaw);
    final parsedPrice = parseOptionalPrice(priceRaw);

    final available = parsedAvailable ?? true;
    final featured = parsedFeatured ?? false;

    DrinkImportRowStatus status = DrinkImportRowStatus.ready;
    var isBlocking = false;
    var isDuplicate = false;

    if (name.trim().isEmpty) {
      status = DrinkImportRowStatus.missingName;
      isBlocking = true;
    } else if (category.trim().isEmpty || !DrinkCategories.isAllowed(category)) {
      status = DrinkImportRowStatus.invalidCategory;
      isBlocking = true;
    } else if (parsedPrice == null && priceRaw.trim().isNotEmpty) {
      status = DrinkImportRowStatus.invalidPrice;
      isBlocking = true;
    } else if (availableRaw.trim().isNotEmpty && parsedAvailable == null) {
      status = DrinkImportRowStatus.invalidAvailable;
      isBlocking = true;
    } else if (featuredRaw.trim().isNotEmpty && parsedFeatured == null) {
      status = DrinkImportRowStatus.invalidFeatured;
      isBlocking = true;
    } else if (existingDrinkNames.contains(name.trim().toLowerCase())) {
      status = DrinkImportRowStatus.possibleDuplicate;
      isDuplicate = true;
    }

    return DrinkImportRow(
      rowNumber: rowNumber,
      name: name,
      category: category,
      priceRaw: priceRaw,
      availableRaw: availableRaw,
      featuredRaw: featuredRaw,
      price: parsedPrice,
      available: available,
      featured: featured,
      status: status,
      statusLabel: _statusLabel(status),
      isBlocking: isBlocking,
      isDuplicateWarning: isDuplicate,
    );
  }

  static String _cellValue(List<String> cells, int index) {
    if (index < 0 || index >= cells.length) return '';
    return cells[index];
  }

  static String _statusLabel(DrinkImportRowStatus status) {
    return switch (status) {
      DrinkImportRowStatus.ready => 'Ready',
      DrinkImportRowStatus.missingName => 'Missing name',
      DrinkImportRowStatus.invalidCategory => 'Invalid category',
      DrinkImportRowStatus.invalidPrice => 'Invalid price',
      DrinkImportRowStatus.invalidAvailable => 'Invalid available',
      DrinkImportRowStatus.invalidFeatured => 'Invalid featured',
      DrinkImportRowStatus.possibleDuplicate => 'Possible duplicate',
    };
  }

  static String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot == -1) return '';
    return filename.substring(dot + 1).toLowerCase();
  }

  static double? parseOptionalPrice(String raw) {
    final trimmed = raw.trim().replaceAll('£', '').replaceAll(',', '');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  static bool? parseOptionalBoolean(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;
    if (const {'true', 'yes', 'y', '1'}.contains(value)) return true;
    if (const {'false', 'no', 'n', '0'}.contains(value)) return false;
    return null;
  }
}
