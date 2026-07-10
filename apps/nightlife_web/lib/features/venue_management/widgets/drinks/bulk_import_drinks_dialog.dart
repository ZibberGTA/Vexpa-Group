import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/files/file_download.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venue/data/models/drink_model.dart';
import '../../../venue/data/venue_drinks_repository.dart';
import '../../data/drink_spreadsheet_service.dart';
import '../../models/drink_import_row.dart';
import 'drink_import_file_picker.dart';

Future<bool> showBulkImportDrinksDialog(
  BuildContext context, {
  required String venueId,
  required String venueName,
  required List<DrinkModel> existingDrinks,
  required VenueDrinksRepository repository,
  String? testCreatedBy,
  Future<({Uint8List bytes, String filename})?> Function()? testPickFile,
  void Function(Uint8List bytes, String filename)? testDownloadBytes,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BulkImportDrinksDialog(
      venueId: venueId,
      venueName: venueName,
      existingDrinks: existingDrinks,
      repository: repository,
      testCreatedBy: testCreatedBy,
      testPickFile: testPickFile,
      testDownloadBytes: testDownloadBytes,
    ),
  ).then((value) => value ?? false);
}

class BulkImportDrinksDialog extends StatefulWidget {
  const BulkImportDrinksDialog({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.existingDrinks,
    required this.repository,
    this.testCreatedBy,
    this.testPickFile,
    this.testDownloadBytes,
  });

  final String venueId;
  final String venueName;
  final List<DrinkModel> existingDrinks;
  final VenueDrinksRepository repository;
  final String? testCreatedBy;
  final Future<({Uint8List bytes, String filename})?> Function()? testPickFile;
  final void Function(Uint8List bytes, String filename)? testDownloadBytes;

  @override
  State<BulkImportDrinksDialog> createState() => _BulkImportDrinksDialogState();
}

class _BulkImportDrinksDialogState extends State<BulkImportDrinksDialog> {
  DrinkImportParseResult? _parseResult;
  String? _uploadedFilename;
  String? _errorMessage;
  String? _statusMessage;
  bool _parsing = false;
  bool _importing = false;
  bool _includeDuplicates = false;

  Set<String> get _existingDrinkNames => widget.existingDrinks
      .map((drink) => drink.name.trim().toLowerCase())
      .toSet();

  bool get _hasPreview =>
      _parseResult != null && !_parseResult!.hasFileError && _parseResult!.rows.isNotEmpty;

  bool get _hasBlockingErrors => _parseResult?.hasBlockingErrors ?? false;

  bool get _hasDuplicateWarnings => _parseResult?.hasDuplicateWarnings ?? false;

  int get _commitCount {
    final rows = _parseResult?.rows ?? const [];
    return DrinkSpreadsheetService.rowsToCommit(
      rows: rows,
      includeDuplicates: _includeDuplicates,
    ).length;
  }

  String? _resolveUserId() {
    if (widget.testCreatedBy != null) return widget.testCreatedBy;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  void _downloadTemplate() {
    final bytes = DrinkSpreadsheetService.buildTemplateBytes();
    if (widget.testDownloadBytes != null) {
      widget.testDownloadBytes!(
        bytes,
        DrinkSpreadsheetService.templateFilename,
      );
    } else {
      downloadBytes(
        bytes,
        DrinkSpreadsheetService.templateFilename,
        mimeType: DrinkSpreadsheetService.templateMimeType,
      );
    }
    setState(() {
      _statusMessage = 'Template downloaded.';
      _errorMessage = null;
    });
  }

  Future<void> _pickAndParseFile() async {
    setState(() {
      _parsing = true;
      _errorMessage = null;
      _statusMessage = 'Uploading and validating file…';
    });

    try {
      ({Uint8List bytes, String filename})? picked;

      if (widget.testPickFile != null) {
        picked = await widget.testPickFile!();
      } else {
        final selected = await pickDrinkImportSpreadsheet();
        if (selected == null) {
          setState(() {
            _parsing = false;
            _statusMessage = null;
          });
          return;
        }
        picked = (
          bytes: Uint8List.fromList(selected.bytes),
          filename: selected.filename,
        );
      }

      if (picked == null) {
        setState(() {
          _parsing = false;
          _statusMessage = null;
        });
        return;
      }

      final parsed = DrinkSpreadsheetService.parseFile(
        bytes: picked.bytes,
        filename: picked.filename,
        existingDrinkNames: _existingDrinkNames,
      );

      if (!mounted) return;
      setState(() {
        _parsing = false;
        _uploadedFilename = picked!.filename;
        _parseResult = parsed;
        _includeDuplicates = false;
        _statusMessage = parsed.hasFileError
            ? null
            : 'Validated ${parsed.rows.length} rows. Review the preview before importing.';
        _errorMessage = parsed.fileError ??
            (parsed.hasBlockingErrors
                ? 'Fix the highlighted rows before importing drinks.'
                : null);
      });
    } on DrinkImportFilePickerException catch (error) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _errorMessage = error.message;
        _statusMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _errorMessage = 'Could not parse the uploaded file.';
        _statusMessage = null;
      });
    }
  }

  Future<void> _importDrinks() async {
    if (!_hasPreview || _hasBlockingErrors || _commitCount == 0) return;

    final userId = _resolveUserId();
    if (userId == null) {
      setState(() => _errorMessage = 'You must be signed in to import drinks.');
      return;
    }

    final rows = DrinkSpreadsheetService.rowsToCommit(
      rows: _parseResult!.rows,
      includeDuplicates: _includeDuplicates,
    );

    setState(() {
      _importing = true;
      _errorMessage = null;
      _statusMessage = 'Importing drinks…';
    });

    try {
      await widget.repository.bulkImportDrinks(
        venueId: widget.venueId,
        venueName: widget.venueName,
        drinks: rows,
        createdBy: userId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _errorMessage = 'Import failed. Please try again.';
        _statusMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _parsing || _importing;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 720),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bulk Import Drinks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Upload an Excel file to add multiple drinks to your venue menu.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instructions',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Upload a spreadsheet with the required columns below. '
                              'Review the preview and confirm import when every row is valid.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Required columns: name, category, price, available, featured',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Categories must match the predefined Vexda drink categories exactly. '
                              'Custom categories are not supported.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          DrinkSpotButton(
                            label: _parsing ? 'Parsing…' : 'Upload Excel File',
                            icon: Icons.upload_file_outlined,
                            compact: true,
                            variant: DrinkSpotButtonVariant.secondary,
                            onPressed: busy ? null : _pickAndParseFile,
                          ),
                          DrinkSpotButton(
                            label: 'Download Template',
                            icon: Icons.download_outlined,
                            compact: true,
                            variant: DrinkSpotButtonVariant.secondary,
                            onPressed: busy ? null : _downloadTemplate,
                          ),
                        ],
                      ),
                      if (_uploadedFilename != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Uploaded file: $_uploadedFilename',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      if (_hasPreview) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _BulkImportPreviewTable(rows: _parseResult!.rows),
                        if (_hasDuplicateWarnings) ...[
                          const SizedBox(height: AppSpacing.md),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _includeDuplicates,
                            activeColor: AppColors.primaryPink,
                            onChanged: busy
                                ? null
                                : (value) => setState(
                                      () => _includeDuplicates = value ?? false,
                                    ),
                            title: const Text(
                              'Import possible duplicates as new drinks',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: const Text(
                              'Rows marked Possible duplicate match an existing drink name.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _statusMessage!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontSize: 13.5,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: DrinkSpotButton(
                      label: 'Cancel',
                      variant: DrinkSpotButtonVariant.ghost,
                      onPressed: busy ? null : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DrinkSpotButton(
                      label: _importing ? 'Importing…' : 'Import Drinks',
                      icon: _importing ? null : Icons.file_upload_outlined,
                      compact: true,
                      onPressed: busy ||
                              !_hasPreview ||
                              _hasBlockingErrors ||
                              _commitCount == 0
                          ? null
                          : _importDrinks,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkImportPreviewTable extends StatelessWidget {
  const _BulkImportPreviewTable({required this.rows});

  final List<DrinkImportRow> rows;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Import preview',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            primary: false,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 48,
              headingTextStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              dataTextStyle: const TextStyle(
                color: AppColors.white,
                fontSize: 12.5,
              ),
              columns: const [
                DataColumn(label: Text('Drink Name')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Available')),
                DataColumn(label: Text('Featured')),
                DataColumn(label: Text('Status')),
              ],
              rows: rows.map((row) {
                final highlight = row.isBlocking || row.isDuplicateWarning;
                final statusColor = row.isBlocking
                    ? AppColors.primaryPink
                    : row.isDuplicateWarning
                        ? Colors.orangeAccent
                        : AppColors.textSecondary;

                return DataRow(
                  color: highlight
                      ? WidgetStatePropertyAll(
                          AppColors.primaryPink.withValues(alpha: 0.08),
                        )
                      : null,
                  cells: [
                    DataCell(Text(row.name.isEmpty ? '—' : row.name)),
                    DataCell(Text(row.category.isEmpty ? '—' : row.category)),
                    DataCell(Text(row.priceRaw.isEmpty ? '—' : row.priceRaw)),
                    DataCell(Text(row.availableRaw.isEmpty ? 'true' : row.availableRaw)),
                    DataCell(Text(row.featuredRaw.isEmpty ? 'false' : row.featuredRaw)),
                    DataCell(
                      Text(
                        row.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
