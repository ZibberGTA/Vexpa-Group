import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/components/drinkspot_button.dart';
import '../../../../../shared/widgets/glass_container.dart';
import '../../../models/venue_trail_participation_presentation.dart';
import '../../../services/venue_trail_participation_action_resolver.dart';

/// Read-only participation application detail with audit timeline and actions.
class TrailParticipationDetailDialog extends StatelessWidget {
  const TrailParticipationDetailDialog({
    super.key,
    required this.application,
    required this.onAction,
    this.busy = false,
  });

  final VenueTrailParticipationApplicationPresentation application;
  final void Function(VenueTrailParticipationAction action)? onAction;
  final bool busy;

  static Future<void> show(
    BuildContext context, {
    required VenueTrailParticipationApplicationPresentation application,
    void Function(VenueTrailParticipationAction action)? onAction,
    bool busy = false,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => TrailParticipationDetailDialog(
        application: application,
        onAction: onAction,
        busy: busy,
      ),
    );
  }

  static String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_monthLabel(local.month)} ${local.year}, $hour:$minute';
  }

  static String _monthLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.trailName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (application.trailBannerUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          child: Image.network(
                            application.trailBannerUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      if (application.trailBannerUrl.isNotEmpty)
                        const SizedBox(height: AppSpacing.md),
                      _DetailRow(
                        label: 'Status',
                        value: application.statusLabel,
                        valueColor: application.statusColor,
                      ),
                      _DetailRow(
                        label: 'Requested position',
                        value: application.positionLabel,
                      ),
                      if (application.trailApplicationWindowLabel.isNotEmpty)
                        _DetailRow(
                          label: 'Application window',
                          value: application.trailApplicationWindowLabel,
                        ),
                      _DetailRow(
                        label: 'Trail stops',
                        value: application.trailMaximumStops == null
                            ? '${application.trailStopCount}'
                            : '${application.trailStopCount} / ${application.trailMaximumStops}',
                      ),
                      if (application.submittedAt != null)
                        _DetailRow(
                          label: 'Submitted',
                          value: _formatTimestamp(application.submittedAt!),
                        ),
                      _DetailRow(
                        label: 'Last updated',
                        value: _formatTimestamp(application.updatedAt),
                      ),
                      if (application.informationRequestNote?.isNotEmpty ??
                          false) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Information requested',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          application.informationRequestNote!,
                          style: const TextStyle(
                            color: AppColors.white,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (application.decisionReason?.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Decision reason',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          application.decisionReason!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Participation note',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        application.participationNote.isEmpty
                            ? 'No note provided.'
                            : application.participationNote,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      if (application.actionGuidance.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          application.actionGuidance,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (application.auditTimeline.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'History',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final entry in application.auditTimeline)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _AuditTimelineRow(entry: entry),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              if (application.actions.length > 1 ||
                  (application.actions.isNotEmpty &&
                      application.actions.first !=
                          VenueTrailParticipationAction.view)) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.end,
                  children: [
                    for (final action in application.actions)
                      if (action != VenueTrailParticipationAction.view)
                        DrinkSpotButton(
                          key: Key('trail_participation_detail_${action.name}'),
                          label: VenueTrailParticipationActionResolver.label(
                            action,
                          ),
                          variant:
                              action == VenueTrailParticipationAction.withdraw
                              ? DrinkSpotButtonVariant.secondary
                              : DrinkSpotButtonVariant.primary,
                          compact: true,
                          onPressed: busy || onAction == null
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  onAction!(action);
                                },
                        ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditTimelineRow extends StatelessWidget {
  const _AuditTimelineRow({required this.entry});

  final VenueTrailParticipationAuditPresentation entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.history_rounded,
          size: 16,
          color: AppColors.primaryPink,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.displayAction,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                '${entry.actorLabel} · ${TrailParticipationDetailDialog._formatTimestamp(entry.timestamp)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (entry.note?.isNotEmpty ?? false)
                Text(
                  entry.note!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
