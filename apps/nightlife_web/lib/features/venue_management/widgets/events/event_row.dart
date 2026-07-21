import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../../venue/data/models/event_model.dart';
import '../../../venue/data/venue_events_repository.dart';
import '../../data/event_write_payload.dart';
import '../../data/venue_management_page_activity_support.dart';
import '../../models/bulk_event_patch.dart';
import '../../models/event_status.dart';
import '../../models/featured_events_limit.dart';
import '../drinks/drink_selection_checkbox.dart';
import '../inline_edit/inline_editable_date_cell.dart';
import '../inline_edit/inline_editable_text_cell.dart';
import '../inline_edit/inline_editable_toggle_cell.dart';
import '../inline_edit/inline_edit_cell_theme.dart';
import 'event_table_layout.dart';

/// Event row with inline-editable table cells.
class EventRow extends StatefulWidget {
  const EventRow({
    super.key,
    required this.event,
    required this.repository,
    required this.venueEvents,
    required this.updatedBy,
    required this.isSelected,
    required this.onSelectionChanged,
    this.showDivider = true,
  });

  final EventModel event;
  final VenueEventsRepository repository;
  final List<EventModel> venueEvents;
  final String? updatedBy;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final bool showDivider;

  @override
  State<EventRow> createState() => _EventRowState();
}

class _EventRowState extends State<EventRow> {
  bool _hovered = false;

  Future<String?> _patch(BulkEventPatch patch) async {
    final userId = widget.updatedBy;
    if (userId == null) return 'You must be signed in to edit events.';

    try {
      await widget.repository.patchEvent(
        eventId: widget.event.id,
        venueId: widget.event.venueId,
        eventTitle: widget.event.title,
        patch: patch,
        updatedBy: userId,
      );
      if (!context.mounted) return null;
      await reloadVenueManagementPageActivity(context);
      return null;
    } catch (_) {
      return 'Could not save. Please try again.';
    }
  }

  Widget _buildCell(EventTableColumn column, EventStatus status) {
    final event = widget.event;

    switch (column) {
      case EventTableColumn.title:
        return Row(
          children: [
            DrinkSelectionCheckbox(
              key: Key('event_select_${event.id}'),
              value: widget.isSelected,
              semanticLabel: 'Select ${event.title}',
              onChanged: widget.onSelectionChanged,
            ),
            Expanded(
              child: InlineEditableTextCell(
                value: event.title,
                displayStyle: InlineEditCellTheme.titleDisplayTextStyle
                    .copyWith(letterSpacing: event.featured ? 0.15 : 0),
                hintText: 'Event title',
                onSave: (value) {
                  if (value.trim().isEmpty) {
                    return Future.value('Event title is required.');
                  }
                  return _patch(BulkEventPatch(title: value));
                },
              ),
            ),
          ],
        );
      case EventTableColumn.date:
        return InlineEditableDateCell(
          value: event.startDateTime,
          displayText: event.formattedDate,
          onSave: (date) => _patch(
            BulkEventPatch(
              startDateTime: mergeEventDate(event.startDateTime, date),
            ),
          ),
        );
      case EventTableColumn.time:
        return InlineEditableTimeCell(
          value: event.formattedTime,
          onSave: (time) => _patch(
            BulkEventPatch(
              startDateTime: mergeEventTime(event.startDateTime, time),
            ),
          ),
        );
      case EventTableColumn.status:
        return _EventStatusToggleCell(
          status: status,
          isActive: event.isActive,
          onSave: (value) => _patch(BulkEventPatch(isActive: value)),
        );
      case EventTableColumn.featured:
        return InlineEditableToggleCell(
          value: event.featured,
          onSave: (value) {
            final limitError = FeaturedEventsLimit.validateEdit(
              event: event,
              wantsFeatured: value,
              venueEvents: widget.venueEvents,
            );
            if (limitError != null) return Future.value(limitError);
            return _patch(BulkEventPatch(featured: value));
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final status = computeEventStatus(event);
    final highlighted = widget.isSelected || _hovered;

    final rowContent = AnimatedContainer(
      duration: PremiumEffects.fast,
      curve: PremiumEffects.easeOut,
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryPurple.withValues(alpha: 0.14)
            : event.featured
                ? AppColors.surfaceElevated.withValues(alpha: 0.72)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: highlighted && !event.featured
            ? PremiumEffects.hoverGlow(intensity: 0.35)
            : null,
      ),
      child: Row(
        children: [
          for (final column in EventTableLayout.columns)
            Expanded(
              flex: EventTableLayout.flexFor(column),
              child: Padding(
                padding: EventTableLayout.cellPadding,
                child: _buildCell(column, status),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: event.featured
              ? Padding(
                  key: Key('event_row_featured_border_${event.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 1),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.trailGold.withValues(alpha: 0.5),
                          AppColors.primaryPink.withValues(alpha: 0.32),
                          AppColors.primaryPurple.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        child: rowContent,
                      ),
                    ),
                  ),
                )
              : rowContent,
        ),
        if (widget.showDivider)
          Divider(
            height: 1,
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

class _EventStatusToggleCell extends StatefulWidget {
  const _EventStatusToggleCell({
    required this.status,
    required this.isActive,
    required this.onSave,
  });

  final EventStatus status;
  final bool isActive;
  final Future<String?> Function(bool value) onSave;

  @override
  State<_EventStatusToggleCell> createState() => _EventStatusToggleCellState();
}

class _EventStatusToggleCellState extends State<_EventStatusToggleCell> {
  InlineCellSaveState _saveState = InlineCellSaveState.idle;
  String? _errorMessage;

  Future<void> _toggle() async {
    if (_saveState == InlineCellSaveState.saving) return;

    setState(() {
      _saveState = InlineCellSaveState.saving;
      _errorMessage = null;
    });

    try {
      final error = await widget.onSave(!widget.isActive);
      if (!mounted) return;

      if (error != null) {
        setState(() {
          _saveState = InlineCellSaveState.error;
          _errorMessage = error;
        });
        return;
      }

      setState(() => _saveState = InlineCellSaveState.success);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _saveState = InlineCellSaveState.idle);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveState = InlineCellSaveState.error;
        _errorMessage = 'Could not save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: EventStatusBadge(status: widget.status),
          ),
        ),
        InlineEditFeedback(
          state: _saveState,
          errorMessage: _errorMessage,
        ),
      ],
    );
  }
}

/// Status badge for event management rows.
class EventStatusBadge extends StatelessWidget {
  const EventStatusBadge({super.key, required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      EventStatus.live => (
          AppColors.primaryPink.withValues(alpha: 0.18),
          AppColors.primaryPink.withValues(alpha: 0.85),
        ),
      EventStatus.upcoming => (
          AppColors.primaryPurple.withValues(alpha: 0.22),
          AppColors.primaryPurple.withValues(alpha: 0.95),
        ),
      EventStatus.ended => (
          AppColors.textSecondary.withValues(alpha: 0.14),
          AppColors.textSecondary.withValues(alpha: 0.85),
        ),
      EventStatus.draft => (
          AppColors.trailGold.withValues(alpha: 0.16),
          AppColors.trailGold.withValues(alpha: 0.92),
        ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: colors.$2.withValues(alpha: 0.35)),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: colors.$2,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class EventTableHeader extends StatelessWidget {
  const EventTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final column in EventTableLayout.columns)
              Expanded(
                flex: EventTableLayout.flexFor(column),
                child: Padding(
                  padding: EventTableLayout.headerPadding(column),
                  child: Text(
                    EventTableLayout.headerLabel(column),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Divider(
          height: 1,
          color: AppColors.primaryPurple.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}
