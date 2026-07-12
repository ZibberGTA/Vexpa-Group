import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:vex_engines/experience/application/experience_drink_import_validator.dart';
import 'package:vex_engines/experience/domain/experience_drink_import.dart';

import '../../venue/data/models/drink_model.dart';
import '../models/drink_categories.dart';
import '../models/drink_import_row.dart';

/// Spreadsheet parsing, validation, template generation and export for drinks.
class DrinkSpreadsheetService {
  DrinkSpreadsheetService._();

  static const requiredColumns = ExperienceDrinkImportValidator.requiredColumns;

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
    final engineRows = rows
        .map(
          (row) => ExperienceDrinkImportRow(
            rowNumber: row.rowNumber,
            name: row.name,
            category: row.category,
            priceRaw: row.priceRaw,
            availableRaw: row.availableRaw,
            featuredRaw: row.featuredRaw,
            price: row.price,
            available: row.available,
            featured: row.featured,
            status: _toEngineStatus(row.status),
            statusLabel: row.statusLabel,
            isBlocking: row.isBlocking,
            isDuplicateWarning: row.isDuplicateWarning,
          ),
        )
        .toList();

    return ExperienceDrinkImportValidator.rowsToCommit(
      rows: engineRows,
      includeDuplicates: includeDuplicates,
    )
        .map(
          (row) => DrinkImportCommitRow(
            name: row.name,
            category: row.category,
            price: row.price,
            available: row.available,
            featured: row.featured,
          ),
        )
        .toList();
  }

  static ExperienceDrinkImportRowStatus _toEngineStatus(
    DrinkImportRowStatus status,
  ) {
    return switch (status) {
      DrinkImportRowStatus.ready => ExperienceDrinkImportRowStatus.ready,
      DrinkImportRowStatus.missingName =>
        ExperienceDrinkImportRowStatus.missingName,
      DrinkImportRowStatus.invalidCategory =>
        ExperienceDrinkImportRowStatus.invalidCategory,
      DrinkImportRowStatus.invalidPrice =>
        ExperienceDrinkImportRowStatus.invalidPrice,
      DrinkImportRowStatus.invalidAvailable =>
        ExperienceDrinkImportRowStatus.invalidAvailable,
      DrinkImportRowStatus.invalidFeatured =>
        ExperienceDrinkImportRowStatus.invalidFeatured,
      DrinkImportRowStatus.possibleDuplicate =>
        ExperienceDrinkImportRowStatus.possibleDuplicate,
    };
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
    final validated = ExperienceDrinkImportValidator.validateRow(
      rowNumber: rowNumber,
      name: _cellValue(cells, columnMap['name']!),
      category: _cellValue(cells, columnMap['category']!),
      priceRaw: _cellValue(cells, columnMap['price']!),
      availableRaw: _cellValue(cells, columnMap['available']!),
      featuredRaw: _cellValue(cells, columnMap['featured']!),
      existingDrinkNames: existingDrinkNames,
      isAllowedCategory: DrinkCategories.isAllowed,
    );

    return DrinkImportRow(
      rowNumber: validated.rowNumber,
      name: validated.name,
      category: validated.category,
      priceRaw: validated.priceRaw,
      availableRaw: validated.availableRaw,
      featuredRaw: validated.featuredRaw,
      price: validated.price,
      available: validated.available,
      featured: validated.featured,
      status: _fromEngineStatus(validated.status),
      statusLabel: validated.statusLabel,
      isBlocking: validated.isBlocking,
      isDuplicateWarning: validated.isDuplicateWarning,
    );
  }

  static DrinkImportRowStatus _fromEngineStatus(
    ExperienceDrinkImportRowStatus status,
  ) {
    return switch (status) {
      ExperienceDrinkImportRowStatus.ready => DrinkImportRowStatus.ready,
      ExperienceDrinkImportRowStatus.missingName =>
        DrinkImportRowStatus.missingName,
      ExperienceDrinkImportRowStatus.invalidCategory =>
        DrinkImportRowStatus.invalidCategory,
      ExperienceDrinkImportRowStatus.invalidPrice =>
        DrinkImportRowStatus.invalidPrice,
      ExperienceDrinkImportRowStatus.invalidAvailable =>
        DrinkImportRowStatus.invalidAvailable,
      ExperienceDrinkImportRowStatus.invalidFeatured =>
        DrinkImportRowStatus.invalidFeatured,
      ExperienceDrinkImportRowStatus.possibleDuplicate =>
        DrinkImportRowStatus.possibleDuplicate,
    };
  }

  static String _cellValue(List<String> cells, int index) {
    if (index < 0 || index >= cells.length) return '';
    return cells[index];
  }

  static String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot == -1) return '';
    return filename.substring(dot + 1).toLowerCase();
  }

  static double? parseOptionalPrice(String raw) =>
      ExperienceDrinkImportValidator.parseOptionalPrice(raw);

  static bool? parseOptionalBoolean(String raw) =>
      ExperienceDrinkImportValidator.parseOptionalBoolean(raw);
}
