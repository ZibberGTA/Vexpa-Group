import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../venue/data/models/deal_model.dart';
import '../../models/deal_types.dart';

class BulkDealEditRowState {
  BulkDealEditRowState({
    required this.dealId,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.availableDays,
    required this.startTime,
    required this.endTime,
    required this.titleController,
    required this.valueController,
    required this.dealType,
    required this.isActive,
    required this.featured,
  });

  final String dealId;
  final String description;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final List<String> availableDays;
  final String startTime;
  final String endTime;
  final TextEditingController titleController;
  final TextEditingController valueController;
  String? dealType;
  bool isActive;
  bool featured;

  factory BulkDealEditRowState.fromDeal(DealModel deal) {
    return BulkDealEditRowState(
      dealId: deal.id,
      description: deal.description,
      startDateTime: deal.startDateTime,
      endDateTime: deal.endDateTime,
      availableDays: List.of(deal.availableDays),
      startTime: deal.startTime,
      endTime: deal.endTime,
      titleController: TextEditingController(text: deal.title),
      valueController: TextEditingController(text: deal.value),
      dealType: DealTypes.normalize(deal.dealType),
      isActive: deal.isActive,
      featured: deal.featured,
    );
  }

  void dispose() {
    titleController.dispose();
    valueController.dispose();
  }

  String? validateTitle() => AddDealFormValidator.validateTitle(titleController.text);

  String? validateDealType() => AddDealFormValidator.validateDealType(dealType);

  String? validateValue() => AddDealFormValidator.validateValue(valueController.text);
}

class BulkEditDealsTable extends StatelessWidget {
  const BulkEditDealsTable({
    super.key,
    required this.rows,
    required this.enabled,
    required this.onRowChanged,
  });

  final List<BulkDealEditRowState> rows;
  final bool enabled;
  final VoidCallback onRowChanged;

  static const _tableMinWidth = 780.0;
  static const _titleFlex = 24;
  static const _typeFlex = 20;
  static const _valueFlex = 12;
  static const _toggleFlex = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < _tableMinWidth
            ? _tableMinWidth
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _BulkEditDealsTableHeader(),
                for (var i = 0; i < rows.length; i++)
                  _BulkEditDealsTableRow(
                    row: rows[i],
                    enabled: enabled,
                    onChanged: onRowChanged,
                    showDivider: i < rows.length - 1,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BulkEditDealsTableHeader extends StatelessWidget {
  const _BulkEditDealsTableHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            _HeaderCell(label: 'Deal Title', flex: BulkEditDealsTable._titleFlex),
            _HeaderCell(label: 'Deal Type', flex: BulkEditDealsTable._typeFlex),
            _HeaderCell(label: 'Value', flex: BulkEditDealsTable._valueFlex),
            _HeaderCell(
              label: 'Active',
              flex: BulkEditDealsTable._toggleFlex,
              centered: true,
            ),
            _HeaderCell(
              label: 'Featured',
              flex: BulkEditDealsTable._toggleFlex,
              centered: true,
            ),
          ],
        ),
        Divider(color: AppColors.primaryPurple.withValues(alpha: 0.16)),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.flex,
    this.centered = false,
  });

  final String label;
  final int flex;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _BulkEditDealsTableRow extends StatelessWidget {
  const _BulkEditDealsTableRow({
    required this.row,
    required this.enabled,
    required this.onChanged,
    required this.showDivider,
  });

  final BulkDealEditRowState row;
  final bool enabled;
  final VoidCallback onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.surfaceElevated.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.22),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.22),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: BulkEditDealsTable._titleFlex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: TextField(
                    controller: row.titleController,
                    enabled: enabled,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: inputDecoration.copyWith(hintText: 'Deal title'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ),
              Expanded(
                flex: BulkEditDealsTable._typeFlex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: DropdownButtonFormField<String>(
                    value: row.dealType,
                    isDense: true,
                    isExpanded: true,
                    decoration: inputDecoration,
                    items: DealTypes.all
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              DealTypes.displayName(type),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: enabled
                        ? (value) {
                            row.dealType = value;
                            onChanged();
                          }
                        : null,
                  ),
                ),
              ),
              Expanded(
                flex: BulkEditDealsTable._valueFlex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: TextField(
                    controller: row.valueController,
                    enabled: enabled,
                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                    decoration: inputDecoration.copyWith(hintText: 'Value'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ),
              Expanded(
                flex: BulkEditDealsTable._toggleFlex,
                child: Center(
                  child: Transform.scale(
                    scale: 0.78,
                    child: Switch(
                      value: row.isActive,
                      activeThumbColor: AppColors.primaryPink,
                      onChanged: enabled
                          ? (value) {
                              row.isActive = value;
                              onChanged();
                            }
                          : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: BulkEditDealsTable._toggleFlex,
                child: Center(
                  child: Transform.scale(
                    scale: 0.78,
                    child: Switch(
                      value: row.featured,
                      activeThumbColor: AppColors.primaryPink,
                      onChanged: enabled
                          ? (value) {
                              row.featured = value;
                              onChanged();
                            }
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: AppColors.primaryPurple.withValues(alpha: 0.1)),
      ],
    );
  }
}
