import 'package:flutter/material.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_submission_payload.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/components/drinkspot_button.dart';
import '../../../../../shared/widgets/glass_container.dart';
import '../../../models/venue_trail_participation_presentation.dart';

enum TrailParticipationFormMode {
  create,
  editDraft,
  respondToInformationRequest,
}

/// Application form for create, draft edit, and information-requested response.
class TrailParticipationApplicationFormDialog extends StatefulWidget {
  const TrailParticipationApplicationFormDialog({
    super.key,
    required this.trail,
    required this.validStopPositions,
    required this.mode,
    this.initialStopOrder,
    this.initialNote = '',
    this.allowSaveDraft = true,
    this.busy = false,
  });

  final VenueTrailDisplayPresentation trail;
  final List<int> validStopPositions;
  final TrailParticipationFormMode mode;
  final int? initialStopOrder;
  final String initialNote;
  final bool allowSaveDraft;
  final bool busy;

  static Future<TrailParticipationFormResult?> show(
    BuildContext context, {
    required VenueTrailDisplayPresentation trail,
    required List<int> validStopPositions,
    required TrailParticipationFormMode mode,
    int? initialStopOrder,
    String initialNote = '',
    bool allowSaveDraft = true,
  }) {
    return showDialog<TrailParticipationFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TrailParticipationApplicationFormDialog(
        trail: trail,
        validStopPositions: validStopPositions,
        mode: mode,
        initialStopOrder: initialStopOrder,
        initialNote: initialNote,
        allowSaveDraft: allowSaveDraft,
      ),
    );
  }

  @override
  State<TrailParticipationApplicationFormDialog> createState() =>
      _TrailParticipationApplicationFormDialogState();
}

class _TrailParticipationApplicationFormDialogState
    extends State<TrailParticipationApplicationFormDialog> {
  late int _selectedStop;
  late final TextEditingController _noteController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final positions = widget.validStopPositions;
    _selectedStop =
        widget.initialStopOrder ?? (positions.isNotEmpty ? positions.last : 1);
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool _validate({required bool forSubmit}) {
    final note = _noteController.text.trim();
    if (forSubmit && note.isEmpty) {
      setState(() => _error = 'Participation note is required.');
      return false;
    }
    if (note.length >
        TrailParticipationSubmissionPayload.maxParticipationNoteLength) {
      setState(
        () => _error =
            'Participation note must not exceed '
            '${TrailParticipationSubmissionPayload.maxParticipationNoteLength} characters.',
      );
      return false;
    }
    if (!widget.validStopPositions.contains(_selectedStop)) {
      setState(() => _error = 'Choose a valid stop position.');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      TrailParticipationFormMode.create => 'Apply to ${widget.trail.name}',
      TrailParticipationFormMode.editDraft => 'Edit application draft',
      TrailParticipationFormMode.respondToInformationRequest =>
        'Respond to information request',
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.trail.participationInstructions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.trail.participationInstructions,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (widget.validStopPositions.length > 1) ...[
                  Text(
                    'Requested stop position',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedStop,
                    dropdownColor: AppColors.surfaceElevated,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                    ),
                    items: [
                      for (final position in widget.validStopPositions)
                        DropdownMenuItem(
                          value: position,
                          child: Text('Stop $position'),
                        ),
                    ],
                    onChanged: widget.busy
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _selectedStop = value);
                            }
                          },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  'Participation note',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _noteController,
                  enabled: !widget.busy,
                  maxLines: 5,
                  maxLength: TrailParticipationSubmissionPayload
                      .maxParticipationNoteLength,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: 'Tell the trail curator why you want to join.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.primaryPink),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                DrinkSpotButton(
                  label: 'Cancel',
                  variant: DrinkSpotButtonVariant.ghost,
                  compact: true,
                  onPressed: widget.busy
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
                if (widget.allowSaveDraft &&
                    widget.mode == TrailParticipationFormMode.create) ...[
                  const SizedBox(height: AppSpacing.sm),
                  DrinkSpotButton(
                    key: const Key('trail_participation_save_draft_button'),
                    label: 'Save draft',
                    variant: DrinkSpotButtonVariant.secondary,
                    compact: true,
                    onPressed: widget.busy
                        ? null
                        : () {
                            if (!_validate(forSubmit: false)) return;
                            Navigator.of(context).pop(
                              TrailParticipationFormResult(
                                stopOrder: _selectedStop,
                                note: _noteController.text.trim(),
                                submit: false,
                              ),
                            );
                          },
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                DrinkSpotButton(
                  key: const Key('trail_participation_submit_button'),
                  label:
                      widget.mode ==
                          TrailParticipationFormMode.respondToInformationRequest
                      ? 'Resubmit'
                      : 'Submit',
                  compact: true,
                  onPressed: widget.busy
                      ? null
                      : () {
                          if (!_validate(forSubmit: true)) return;
                          Navigator.of(context).pop(
                            TrailParticipationFormResult(
                              stopOrder: _selectedStop,
                              note: _noteController.text.trim(),
                              submit: true,
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class TrailParticipationFormResult {
  const TrailParticipationFormResult({
    required this.stopOrder,
    required this.note,
    required this.submit,
  });

  final int stopOrder;
  final String note;
  final bool submit;
}
