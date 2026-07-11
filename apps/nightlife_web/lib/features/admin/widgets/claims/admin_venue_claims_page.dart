import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vex_engines/claim/application/claim_evidence_interpretation.dart';
import 'package:vex_engines/claim/application/claim_summary_service.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/drinkspot_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../venue_claims/data/venue_claim_repository.dart';
import '../../../venue_claims/models/venue_claim.dart';
import '../../permissions/admin_permission_constants.dart';
import '../../permissions/permission_service.dart';
import '../../permissions/staff_permission.dart';
import '../../../venue_management/widgets/page/venue_dashboard_page_widgets.dart';

class AdminVenueClaimsPage extends StatefulWidget {
  const AdminVenueClaimsPage({
    super.key,
    required this.permissions,
    this.repository,
  });

  final PermissionService permissions;
  final VenueClaimRepository? repository;

  @override
  State<AdminVenueClaimsPage> createState() => _AdminVenueClaimsPageState();
}

class _AdminVenueClaimsPageState extends State<AdminVenueClaimsPage> {
  static const _claimSummaryService = ClaimSummaryService();

  late final VenueClaimRepository _repository =
      widget.repository ?? VenueClaimRepository();
  VenueClaim? _selectedClaim;
  bool _busy = false;

  bool get _canReview =>
      widget.permissions.has(StaffPermission.venueClaimApprove);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VenueClaim>>(
      stream: _repository.watchClaimsForAdmin(),
      builder: (context, snapshot) {
        final claims = snapshot.data ?? const <VenueClaim>[];
        final metrics = _claimSummaryService.adminMetrics(
          claims.map((claim) => claim.toClaimListEntry()),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VenuePageMetricRow(
              metrics: [
                VenuePageMetricCard(
                  label: 'Total Claims',
                  value: '${metrics.total}',
                  icon: Icons.fact_check_rounded,
                ),
                VenuePageMetricCard(
                  label: 'Pending Review',
                  value: '${metrics.pendingReview}',
                  icon: Icons.hourglass_top_rounded,
                ),
                VenuePageMetricCard(
                  label: 'Auto Approved',
                  value: '${metrics.autoApproved}',
                  icon: Icons.flash_on_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _ClaimsTable(
              claims: claims,
              selectedClaimId: _selectedClaim?.id,
              canReview: _canReview,
              onSelect: (claim) => setState(() => _selectedClaim = claim),
              onApprove: _canReview ? _approve : null,
              onReject: _canReview ? _reject : null,
              onMoreInfo: _canReview ? _requestMoreInfo : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            _ClaimDetailPanel(
              claim: _selectedClaim,
              auditStream: _selectedClaim == null
                  ? null
                  : _repository.watchClaimAudit(_selectedClaim!.id),
              canReview: _canReview,
              busy: _busy,
              onApprove: _canReview && _selectedClaim != null
                  ? () => _approve(_selectedClaim!)
                  : null,
              onReject: _canReview && _selectedClaim != null
                  ? () => _reject(_selectedClaim!)
                  : null,
              onMoreInfo: _canReview && _selectedClaim != null
                  ? () => _requestMoreInfo(_selectedClaim!)
                  : null,
            ),
          ],
        );
      },
    );
  }

  Future<void> _approve(VenueClaim claim) async {
    final confirmed = await _confirm(
      title: 'Approve claim?',
      message:
          'This assigns the owner, activates venue ownership and publishes draft changes.',
      noteRequired: false,
    );
    if (confirmed == null) return;
    await _runReviewAction(
      () => _repository.approveClaim(
        claimId: claim.id,
        reviewerUid: FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        notes: confirmed,
        currentStatus: claim.status,
        reviewerCanApprove: _canReview,
      ),
      'Claim approved and draft published.',
    );
  }

  Future<void> _reject(VenueClaim claim) async {
    final notes = await _confirm(
      title: 'Reject claim?',
      message: 'The claimant keeps their draft and can resubmit later.',
      noteRequired: true,
    );
    if (notes == null) return;
    await _runReviewAction(
      () => _repository.rejectClaim(
        claimId: claim.id,
        reviewerUid: FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        notes: notes,
        currentStatus: claim.status,
        reviewerCanApprove: _canReview,
      ),
      'Claim rejected. Draft work was kept.',
    );
  }

  Future<void> _requestMoreInfo(VenueClaim claim) async {
    final notes = await _confirm(
      title: 'Request more information?',
      message: 'The claimant can continue editing and resubmit evidence.',
      noteRequired: true,
    );
    if (notes == null) return;
    await _runReviewAction(
      () => _repository.requestMoreInformation(
        claimId: claim.id,
        reviewerUid: FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        notes: notes,
        currentStatus: claim.status,
        reviewerCanApprove: _canReview,
      ),
      'More information requested.',
    );
  }

  Future<void> _runReviewAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on VenueClaimBackendException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _confirm({
    required String title,
    required String message,
    required bool noteRequired,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Text(title, style: const TextStyle(color: AppColors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: noteRequired
                      ? 'Review notes required'
                      : 'Review notes',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.28),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primaryPink),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (noteRequired && controller.text.trim().isEmpty) return;
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }
}

class _ClaimsTable extends StatelessWidget {
  const _ClaimsTable({
    required this.claims,
    required this.selectedClaimId,
    required this.canReview,
    required this.onSelect,
    required this.onApprove,
    required this.onReject,
    required this.onMoreInfo,
  });

  final List<VenueClaim> claims;
  final String? selectedClaimId;
  final bool canReview;
  final ValueChanged<VenueClaim> onSelect;
  final ValueChanged<VenueClaim>? onApprove;
  final ValueChanged<VenueClaim>? onReject;
  final ValueChanged<VenueClaim>? onMoreInfo;

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty) {
      return const VenuePageSection(
        title: 'Venue Claims',
        child: Text(
          'No venue claims have been submitted yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return VenuePageSection(
      title: 'Venue Claims',
      trailing: Text(
        '${claims.length} shown',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          columns: const [
            DataColumn(label: Text('Venue')),
            DataColumn(label: Text('Claimant')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Confidence')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: claims.map((claim) {
            return DataRow(
              selected: selectedClaimId == claim.id,
              onSelectChanged: (_) => onSelect(claim),
              cells: [
                DataCell(
                  Text(
                    claim.venueName.isEmpty ? claim.venueId : claim.venueName,
                  ),
                ),
                DataCell(
                  Text(
                    claim.claimantEmail.isEmpty
                        ? claim.claimantUid
                        : claim.claimantEmail,
                  ),
                ),
                DataCell(Text(_formatDate(claim.submittedAt))),
                DataCell(_ConfidenceChip(score: claim.confidenceScore)),
                DataCell(_StatusChip(status: claim.status)),
                DataCell(
                  _InlineClaimActions(
                    claim: claim,
                    canReview: canReview,
                    onView: () => onSelect(claim),
                    onApprove: onApprove == null
                        ? null
                        : () => onApprove!(claim),
                    onReject: onReject == null ? null : () => onReject!(claim),
                    onMoreInfo: onMoreInfo == null
                        ? null
                        : () => onMoreInfo!(claim),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _InlineClaimActions extends StatelessWidget {
  const _InlineClaimActions({
    required this.claim,
    required this.canReview,
    required this.onView,
    required this.onApprove,
    required this.onReject,
    required this.onMoreInfo,
  });

  final VenueClaim claim;
  final bool canReview;
  final VoidCallback onView;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onMoreInfo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.visibility_outlined,
          tooltip: 'View claim detail',
          onPressed: onView,
        ),
        _ActionIcon(
          icon: Icons.check_circle_outline_rounded,
          tooltip: canReview ? 'Approve claim' : kAdminPermissionDeniedTooltip,
          onPressed: canReview && claim.isPending ? onApprove : null,
        ),
        _ActionIcon(
          icon: Icons.cancel_outlined,
          tooltip: canReview ? 'Reject claim' : kAdminPermissionDeniedTooltip,
          onPressed: canReview && claim.isPending ? onReject : null,
        ),
        _ActionIcon(
          icon: Icons.contact_support_outlined,
          tooltip: canReview
              ? 'Request more information'
              : kAdminPermissionDeniedTooltip,
          onPressed: canReview && claim.isPending ? onMoreInfo : null,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.white.withValues(alpha: 0.92)
              : AppColors.textSecondary.withValues(alpha: 0.42),
        ),
      ),
    );
  }
}

class _ClaimDetailPanel extends StatelessWidget {
  const _ClaimDetailPanel({
    required this.claim,
    required this.auditStream,
    required this.canReview,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onMoreInfo,
  });

  final VenueClaim? claim;
  final Stream<List<VenueClaimAuditEvent>>? auditStream;
  final bool canReview;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onMoreInfo;

  @override
  Widget build(BuildContext context) {
    final claim = this.claim;
    if (claim == null) {
      return const VenuePageSection(
        title: 'Claim Detail',
        child: Text(
          'Select a claim to review evidence, confidence signals and draft changes.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return VenuePageSection(
      title: 'Claim Detail',
      trailing: _StatusChip(status: claim.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _DetailCard(label: 'Venue', value: claim.venueName),
              _DetailCard(label: 'Claimant', value: claim.claimantEmail),
              _DetailCard(
                label: 'Confidence',
                value: '${claim.confidenceScore}%',
              ),
              _DetailCard(
                label: 'Auto Approved',
                value: claim.autoApproved ? 'Yes' : 'No',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ConfidenceReasonsList(reasons: claim.confidenceReasons),
          const SizedBox(height: AppSpacing.lg),
          _EvidenceList(claim: claim),
          const SizedBox(height: AppSpacing.lg),
          _DraftChangesList(data: claim.draftVenueData),
          const SizedBox(height: AppSpacing.lg),
          _AuditTimeline(auditStream: auditStream),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              DrinkSpotButton(
                label: busy ? 'Approving...' : 'Approve',
                icon: Icons.check_rounded,
                onPressed: canReview && claim.isPending && !busy
                    ? onApprove
                    : null,
              ),
              DrinkSpotButton(
                label: 'Reject',
                icon: Icons.close_rounded,
                variant: DrinkSpotButtonVariant.secondary,
                onPressed: canReview && claim.isPending && !busy
                    ? onReject
                    : null,
              ),
              DrinkSpotButton(
                label: 'Request More Information',
                icon: Icons.contact_support_outlined,
                variant: DrinkSpotButtonVariant.ghost,
                onPressed: canReview && claim.isPending && !busy
                    ? onMoreInfo
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceList extends StatelessWidget {
  const _EvidenceList({
    required this.claim,
    this.interpretation = const ClaimEvidenceInterpretation(),
  });

  final VenueClaim claim;
  final ClaimEvidenceInterpretation interpretation;

  @override
  Widget build(BuildContext context) {
    final rows = interpretation
        .reviewFields(claim.submittedEvidence)
        .map((field) => (field.label, field.displayValue))
        .toList(growable: false);
    return _InfoBlock(title: 'Evidence Submitted', rows: rows);
  }
}

class _ConfidenceReasonsList extends StatelessWidget {
  const _ConfidenceReasonsList({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return _InfoBlock(
      title: 'Confidence Reasons',
      rows: reasons.isEmpty
          ? const [('Scoring', 'No confidence reasons recorded yet.')]
          : reasons
                .map((reason) => ('Matched', reason))
                .toList(growable: false),
    );
  }
}

class _AuditTimeline extends StatelessWidget {
  const _AuditTimeline({required this.auditStream});

  final Stream<List<VenueClaimAuditEvent>>? auditStream;

  @override
  Widget build(BuildContext context) {
    final stream = auditStream;
    if (stream == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<List<VenueClaimAuditEvent>>(
      stream: stream,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <VenueClaimAuditEvent>[];
        return _InfoBlock(
          title: 'Audit Timeline',
          rows: events.isEmpty
              ? const [('Audit', 'No audit events yet.')]
              : events
                    .map(
                      (event) => (
                        event.type,
                        event.message.trim().isEmpty
                            ? event.actorRole
                            : event.message,
                      ),
                    )
                    .toList(growable: false),
        );
      },
    );
  }
}

class _DraftChangesList extends StatelessWidget {
  const _DraftChangesList({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rows = data.entries
        .where((entry) => entry.key != 'draftChecklist')
        .map((entry) => (entry.key, entry.value.toString()))
        .toList(growable: false);
    return _InfoBlock(
      title: 'Draft Changes',
      rows: rows.isEmpty ? const [('Draft', 'No draft changes yet.')] : rows,
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      row.$1,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2.trim().isEmpty ? '—' : row.$2,
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppSpacing.radiusMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value.trim().isEmpty ? '—' : value,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final VenueClaimStatus status;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      label: status.label,
      color: switch (status) {
        VenueClaimStatus.completed ||
        VenueClaimStatus.autoApproved ||
        VenueClaimStatus.approved => Colors.greenAccent,
        VenueClaimStatus.rejected => Colors.redAccent,
        VenueClaimStatus.needsMoreInfo => Colors.orangeAccent,
        VenueClaimStatus.error => Colors.redAccent,
        VenueClaimStatus.draft => AppColors.textSecondary,
        VenueClaimStatus.pendingReview => AppColors.primaryPink,
      },
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      label: '$score%',
      color: score >= 75 ? Colors.greenAccent : AppColors.primaryPink,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
