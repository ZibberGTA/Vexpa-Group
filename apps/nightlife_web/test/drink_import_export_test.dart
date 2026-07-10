import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue/data/models/drink_model.dart';
import 'package:nightlife_web/features/venue_management/data/drink_spreadsheet_service.dart';
import 'package:nightlife_web/features/venue_management/models/drink_categories.dart';
import 'package:nightlife_web/features/venue_management/models/drink_import_row.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

void main() {
  group('DrinkSpreadsheetService template', () {
    test('template includes required columns and example rows', () {
      final bytes = DrinkSpreadsheetService.buildTemplateBytes();
      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
      final rows = decoder.tables.values.first.rows;

      expect(rows.first.map((cell) => cell?.toString()), [
        'name',
        'category',
        'price',
        'available',
        'featured',
      ]);
      expect(rows[1][0]?.toString(), 'Espresso Martini');
      expect(rows[1][1]?.toString(), 'Cocktails');
      expect(rows[2][0]?.toString(), 'Peroni Pint');
      expect(rows[2][1]?.toString(), 'Beer');
    });
  });

  group('DrinkSpreadsheetService parse and validate', () {
    Uint8List buildCsv(List<List<String>> rows) {
      final content = csv.encode(rows);
      return Uint8List.fromList(utf8.encode(content));
    }

    test('valid rows show Ready preview status', () {
      final result = DrinkSpreadsheetService.parseFile(
        bytes: buildCsv([
          DrinkSpreadsheetService.requiredColumns,
          ['Espresso Martini', 'Cocktails', '9.50', 'true', 'false'],
          ['Peroni Pint', 'Beer', '6.20', 'yes', 'no'],
        ]),
        filename: 'drinks.csv',
        existingDrinkNames: const {},
      );

      expect(result.fileError, isNull);
      expect(result.rows, hasLength(2));
      expect(result.rows.every((row) => row.status == DrinkImportRowStatus.ready), isTrue);
      expect(result.hasBlockingErrors, isFalse);
    });

    test('missing name fails validation', () {
      final result = DrinkSpreadsheetService.parseFile(
        bytes: buildCsv([
          DrinkSpreadsheetService.requiredColumns,
          ['', 'Beer', '6.20', 'true', 'false'],
        ]),
        filename: 'drinks.csv',
        existingDrinkNames: const {},
      );

      expect(result.rows.single.status, DrinkImportRowStatus.missingName);
      expect(result.hasBlockingErrors, isTrue);
    });

    test('invalid category fails validation', () {
      final result = DrinkSpreadsheetService.parseFile(
        bytes: buildCsv([
          DrinkSpreadsheetService.requiredColumns,
          ['Mystery Drink', 'Secret Menu', '8.00', 'true', 'false'],
        ]),
        filename: 'drinks.csv',
        existingDrinkNames: const {},
      );

      expect(result.rows.single.status, DrinkImportRowStatus.invalidCategory);
      expect(result.hasBlockingErrors, isTrue);
    });

    test('invalid price fails validation', () {
      final result = DrinkSpreadsheetService.parseFile(
        bytes: buildCsv([
          DrinkSpreadsheetService.requiredColumns,
          ['House Lager', 'Beer', 'abc', 'true', 'false'],
        ]),
        filename: 'drinks.csv',
        existingDrinkNames: const {},
      );

      expect(result.rows.single.status, DrinkImportRowStatus.invalidPrice);
      expect(result.hasBlockingErrors, isTrue);
    });

    test('duplicate names are flagged as warnings', () {
      final result = DrinkSpreadsheetService.parseFile(
        bytes: buildCsv([
          DrinkSpreadsheetService.requiredColumns,
          ['House Lager', 'Beer', '6.20', 'true', 'false'],
        ]),
        filename: 'drinks.csv',
        existingDrinkNames: {'house lager'},
      );

      expect(result.rows.single.status, DrinkImportRowStatus.possibleDuplicate);
      expect(result.hasBlockingErrors, isFalse);
      expect(result.hasDuplicateWarnings, isTrue);
    });
  });

  group('DrinkSpreadsheetService export', () {
    test('export includes correct columns and values', () {
      final bytes = DrinkSpreadsheetService.exportDrinksBytes([
        DrinkModel(
          id: 'drink-1',
          venueId: 'venue-1',
          name: 'Espresso Martini',
          category: 'cocktails',
          price: 9.5,
          description: '',
          available: true,
          featured: false,
          isDeleted: false,
        ),
      ]);

      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
      final rows = decoder.tables.values.first.rows;

      expect(rows.first.map((cell) => cell?.toString()), [
        'name',
        'category',
        'price',
        'available',
        'featured',
      ]);
      expect(rows[1][0]?.toString(), 'Espresso Martini');
      expect(rows[1][1]?.toString(), 'Cocktails');
      expect(rows[1][2]?.toString(), '9.50');
      expect(rows[1][3]?.toString(), 'true');
      expect(rows[1][4]?.toString(), 'false');
    });

    test('export leaves price blank when drink has no valid price', () {
      final bytes = DrinkSpreadsheetService.exportDrinksBytes([
        DrinkModel(
          id: 'drink-no-price',
          venueId: 'venue-1',
          name: 'Ask For Price',
          category: 'cocktails',
          price: 0,
          description: '',
          available: true,
          featured: false,
          isDeleted: false,
        ),
        DrinkModel(
          id: 'drink-with-price',
          venueId: 'venue-1',
          name: 'Espresso Martini',
          category: 'cocktails',
          price: 9.5,
          description: '',
          available: true,
          featured: false,
          isDeleted: false,
        ),
      ]);

      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
      final rows = decoder.tables.values.first.rows;

      final blankPrice = rows[1][2];
      expect(blankPrice == null || blankPrice.toString().trim().isEmpty, isTrue);
      expect(rows[2][2]?.toString(), '9.50');
    });

    test('export filename slugifies venue name and date', () {
      final filename = DrinkSpreadsheetService.exportFilename(
        'Copper Lantern',
        DateTime(2026, 6, 28),
      );
      expect(filename, 'vexda-drinks-copper-lantern-2026-06-28.xlsx');
    });
  });

  group('DrinkSpreadsheetService commit rows', () {
    test('rowsToCommit skips duplicates unless confirmed', () {
      final rows = [
        DrinkImportRow(
          rowNumber: 2,
          name: 'House Lager',
          category: 'Beer',
          priceRaw: '6.20',
          availableRaw: 'true',
          featuredRaw: 'false',
          price: 6.2,
          available: true,
          featured: false,
          status: DrinkImportRowStatus.ready,
          statusLabel: 'Ready',
          isBlocking: false,
          isDuplicateWarning: false,
        ),
        DrinkImportRow(
          rowNumber: 3,
          name: 'Duplicate Lager',
          category: 'Beer',
          priceRaw: '6.20',
          availableRaw: 'true',
          featuredRaw: 'false',
          price: 6.2,
          available: true,
          featured: false,
          status: DrinkImportRowStatus.possibleDuplicate,
          statusLabel: 'Possible duplicate',
          isBlocking: false,
          isDuplicateWarning: true,
        ),
      ];

      expect(
        DrinkSpreadsheetService.rowsToCommit(rows: rows, includeDuplicates: false),
        hasLength(1),
      );
      expect(
        DrinkSpreadsheetService.rowsToCommit(rows: rows, includeDuplicates: true),
        hasLength(2),
      );
    });
  });

  group('DrinkSpreadsheetService boolean parsing', () {
    test('accepts supported boolean formats', () {
      expect(DrinkSpreadsheetService.parseOptionalBoolean('yes'), isTrue);
      expect(DrinkSpreadsheetService.parseOptionalBoolean('N'), isFalse);
      expect(DrinkSpreadsheetService.parseOptionalBoolean('1'), isTrue);
      expect(DrinkSpreadsheetService.parseOptionalBoolean('0'), isFalse);
      expect(DrinkSpreadsheetService.parseOptionalBoolean('maybe'), isNull);
    });
  });
}
