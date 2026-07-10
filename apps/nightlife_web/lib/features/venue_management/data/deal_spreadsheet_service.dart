import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../venue/data/models/deal_model.dart';
import '../models/deal_types.dart';

/// Spreadsheet export for venue deals.
class DealSpreadsheetService {
  DealSpreadsheetService._();

  static const exportColumns = [
    'title',
    'description',
    'dealType',
    'value',
    'startDate',
    'endDate',
    'availableDays',
    'startTime',
    'endTime',
    'active',
    'featured',
  ];

  static const templateMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  static Uint8List exportDealsBytes(List<DealModel> deals) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? excel.sheets.keys.first;
    if (defaultSheet != 'Deals') {
      excel.rename(defaultSheet, 'Deals');
    }
    final sheet = excel['Deals'];

    sheet.appendRow(exportColumns.map((value) => TextCellValue(value)).toList());

    for (final deal in deals) {
      sheet.appendRow([
        TextCellValue(deal.title),
        TextCellValue(deal.description),
        TextCellValue(DealTypes.displayName(deal.dealType)),
        TextCellValue(deal.value),
        TextCellValue(deal.formattedStartDate == '—' ? '' : deal.formattedStartDate),
        TextCellValue(deal.formattedEndDate == '—' ? '' : deal.formattedEndDate),
        TextCellValue(deal.availableDays.join(', ')),
        TextCellValue(deal.startTime),
        TextCellValue(deal.endTime),
        TextCellValue(deal.isActive.toString()),
        TextCellValue(deal.featured.toString()),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Could not export deals spreadsheet.');
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
    return 'vexda-deals-$safeSlug-$stamp.xlsx';
  }
}
