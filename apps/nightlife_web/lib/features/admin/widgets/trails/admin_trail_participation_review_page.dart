import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../venue_management/widgets/page/venue_dashboard_page_widgets.dart';
import '../../data/admin_trail_participation_review_repository.dart';
import '../../models/admin_trail_participation_review_presentation.dart';
import '../../permissions/admin_permission_constants.dart';
import '../../permissions/permission_service.dart';
import '../../permissions/staff_permission.dart';
import '../../services/admin_trail_participation_action_resolver.dart';

class AdminTrailParticipationReviewPage extends StatefulWidget {
  const AdminTrailParticipationReviewPage({
    super.key,
    required this.permissions,
    this.repository,
    this.actorUidOverride,
  });

  final PermissionService permissions;
  final AdminTrailParticipationReviewRepository? repository;
  final String? actorUidOverride;

  @override
  State<AdminTrailParticipationReviewPage> createState() =>
      _AdminTrailParticipationReviewPageState();
}

class _AdminTrailParticipationReviewPageState
    extends State<AdminTrailParticipationReviewPage> {
  late final AdminTrailParticipationReviewRepository _repository =
      widget.repository ?? AdminTrailParticipationReviewRepository();

  AdminTrailParticipationInboxFilters _filters =
      const AdminTrailParticipationInboxFilters();
  AdminTrailParticipationInboxPresentation? _inbox;
  AdminTrailParticipationRequestDetailPresentation? _selectedDetail;
  bool _loading = true;
  bool _detailLoading = false;
  bool _busy = false;
  String? _loadError;
  String? _conflictMessage;

  bool get _canView =>
      widget.permissions.has(StaffPermission.trailsView) ||
      widget.permissions.has(StaffPermission.trailsManage);

  bool get _canManage => widget.permissions.has(StaffPermission.trailsManage);

  @override
  void initState() {
    super.initState();
    _refreshInbox();
  }

  String get _actorUid =>
      widget.actorUidOverride ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _refreshInbox({String? selectRequestId}) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final inbox = await _repository.loadInbox(
      actorUid: _actorUid,
      canView: _canView,
      canManage: _canManage,
      filters: _filters,
    );

    if (!mounted) return;

    setState(() {
      _inbox = inbox;
      _loading = false;
      if (!inbox.ok) {
        _loadError = inbox.errorMessage;
      }
    });

    if (selectRequestId != null && inbox.ok) {
      await _openDetail(selectRequestId);
    } else if (_selectedDetail != null && inbox.ok) {
      final stillVisible = inbox.items.any(
        (item) => item.requestId == _selectedDetail!.requestId,
      );
      if (!stillVisible) {
        setState(() => _selectedDetail = null);
      }
    }
  }

  Future<void> _openDetail(String requestId) async {
    setState(() {
      _detailLoading = true;
      _conflictMessage = null;
    });

    final result = await _repository.loadDetail(
      requestId: requestId,
      canView: _canView,
      canManage: _canManage,
    );

    if (!mounted) return;

    setState(() {
      _detailLoading = false;
      if (result.ok && result.detail != null) {
        _selectedDetail = result.detail;
      } else {
        _selectedDetail = null;
        _loadError = result.errorMessage;
      }
    });
  }

  Future<void> _requestInformation(
    AdminTrailParticipationRequestDetailPresentation detail,
  ) async {
    final note = await _promptNote(
      title: 'Request information',
      message:
          'The venue will see this note and can respond before resubmitting.',
      noteRequired: true,
    );
    if (note == null) return;

    await _runDecision(
      () => _repository.requestInformation(
        actorUid: _actorUid,
        canManage: _canManage,
        detail: detail,
        reviewerNote: note,
      ),
      successMessage: 'Information request sent to the venue.',
    );
  }

  Future<void> _approve(
    AdminTrailParticipationRequestDetailPresentation detail,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ApprovalConfirmationDialog(detail: detail),
    );
    if (confirmed != true) return;

    final note = await _promptNote(
      title: 'Optional administrator note',
      message: 'Add an optional note for the audit history, or cancel to skip.',
      noteRequired: false,
    );

    await _runDecision(
      () => _repository.approve(
        actorUid: _actorUid,
        canManage: _canManage,
        detail: detail,
        administratorNote: note,
      ),
      successMessage:
          'Participation request approved. Trail stops are not changed automatically.',
    );
  }

  Future<void> _reject(
    AdminTrailParticipationRequestDetailPresentation detail,
  ) async {
    final reason = await _promptNote(
      title: 'Reject request',
      message: 'Provide a rejection reason visible to the venue.',
      noteRequired: true,
    );
    if (reason == null) return;

    await _runDecision(
      () => _repository.reject(
        actorUid: _actorUid,
        canManage: _canManage,
        detail: detail,
        rejectionReason: reason,
      ),
      successMessage: 'Participation request rejected.',
    );
  }

  Future<void> _runDecision(
    Future<AdminTrailParticipationDecisionResult> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;

    setState(() => _busy = false);

    if (result.ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      setState(() {
        _selectedDetail = result.refreshedDetail;
        _conflictMessage = null;
      });
      await _refreshInbox(selectRequestId: result.refreshedDetail?.requestId);
      return;
    }

    if (result.isRevisionConflict) {
      setState(() {
        _conflictMessage = result.errorMessage;
        _selectedDetail = result.refreshedDetail ?? _selectedDetail;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.errorMessage ?? 'Review action failed.')),
    );
  }

  Future<String?> _promptNote({
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
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
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
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: noteRequired
                        ? 'Reviewer note required'
                        : 'Administrator note',
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

  @override
  Widget build(BuildContext context) {
    if (!_canView) {
      return const VenuePageSection(
        title: 'Trail Participation Review',
        child: Text(
          'You do not have permission to view participation reviews.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    if (_loadError != null && (_inbox == null || !_inbox!.ok)) {
      return VenuePageSection(
        title: 'Trail Participation Review',
        child: Text(
          _loadError!,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final inbox = _inbox!;
    final desktop = Breakpoints.isDesktop(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _FilterBar(
          filters: _filters,
          trailFilters: inbox.availableTrailFilters,
          onChanged: (filters) {
            setState(() => _filters = filters);
            _refreshInbox();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _InboxPanel(
                  items: inbox.items,
                  selectedRequestId: _selectedDetail?.requestId,
                  onSelect: _openDetail,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                flex: 4,
                child: _DetailPanel(
                  detail: _selectedDetail,
                  loading: _detailLoading,
                  busy: _busy,
                  canManage: _canManage,
                  conflictMessage: _conflictMessage,
                  onRefresh: _selectedDetail == null
                      ? null
                      : () => _openDetail(_selectedDetail!.requestId),
                  onRequestInformation: _canManage && _selectedDetail != null
                      ? () => _requestInformation(_selectedDetail!)
                      : null,
                  onApprove: _canManage && _selectedDetail != null
                      ? () => _approve(_selectedDetail!)
                      : null,
                  onReject: _canManage && _selectedDetail != null
                      ? () => _reject(_selectedDetail!)
                      : null,
                ),
              ),
            ],
          )
        else ...[
          _InboxPanel(
            items: inbox.items,
            selectedRequestId: _selectedDetail?.requestId,
            onSelect: _openDetail,
          ),
          const SizedBox(height: AppSpacing.xl),
          _DetailPanel(
            detail: _selectedDetail,
            loading: _detailLoading,
            busy: _busy,
            canManage: _canManage,
            conflictMessage: _conflictMessage,
            onRefresh: _selectedDetail == null
                ? null
                : () => _openDetail(_selectedDetail!.requestId),
            onRequestInformation: _canManage && _selectedDetail != null
                ? () => _requestInformation(_selectedDetail!)
                : null,
            onApprove: _canManage && _selectedDetail != null
                ? () => _approve(_selectedDetail!)
                : null,
            onReject: _canManage && _selectedDetail != null
                ? () => _reject(_selectedDetail!)
                : null,
          ),
        ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.trailFilters,
    required this.onChanged,
  });

  final AdminTrailParticipationInboxFilters filters;
  final List<String> trailFilters;
  final ValueChanged<AdminTrailParticipationInboxFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = !Breakpoints.isDesktop(context);
    final searchField = TextField(
      decoration: const InputDecoration(
        labelText: 'Search venue',
        prefixIcon: Icon(Icons.search_rounded),
      ),
      onChanged: (value) => onChanged(filters.copyWith(venueSearch: value)),
    );
    final statusDropdown = DropdownButtonFormField<String>(
      initialValue: filters.statusFilter,
      decoration: const InputDecoration(labelText: 'Status'),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All review-ready')),
        DropdownMenuItem(value: 'Submitted', child: Text('Submitted')),
        DropdownMenuItem(
          value: 'Under review',
          child: Text('Under review'),
        ),
        DropdownMenuItem(
          value: 'Information requested',
          child: Text('Information requested'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        onChanged(filters.copyWith(statusFilter: value));
      },
    );
    final trailDropdown = DropdownButtonFormField<String>(
      initialValue: filters.trailFilter,
      decoration: const InputDecoration(labelText: 'Trail'),
      items: [
        const DropdownMenuItem(value: 'All', child: Text('All trails')),
        for (final trail in trailFilters)
          DropdownMenuItem(value: trail, child: Text(trail)),
      ],
      onChanged: (value) {
        if (value == null) return;
        onChanged(filters.copyWith(trailFilter: value));
      },
    );
    final sortChip = FilterChip(
      label: Text(filters.oldestFirst ? 'Oldest first' : 'Newest first'),
      selected: filters.oldestFirst,
      onSelected: (_) =>
          onChanged(filters.copyWith(oldestFirst: !filters.oldestFirst)),
    );

    if (compact) {
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          SizedBox(width: double.infinity, child: searchField),
          SizedBox(width: double.infinity, child: statusDropdown),
          SizedBox(width: double.infinity, child: trailDropdown),
          sortChip,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: searchField),
        const SizedBox(width: AppSpacing.md),
        SizedBox(width: 180, child: statusDropdown),
        const SizedBox(width: AppSpacing.md),
        SizedBox(width: 220, child: trailDropdown),
        const SizedBox(width: AppSpacing.md),
        sortChip,
      ],
    );
  }
}

class _InboxPanel extends StatelessWidget {
  const _InboxPanel({
    required this.items,
    required this.selectedRequestId,
    required this.onSelect,
  });

  final List<AdminTrailParticipationInboxItemPresentation> items;
  final String? selectedRequestId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const VenuePageSection(
        title: 'Review inbox',
        child: Text(
          'No participation requests are waiting for administrator review.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final compact = !Breakpoints.isDesktop(context);
    if (compact) {
      return VenuePageSection(
        title: 'Review inbox',
        trailing: Text(
          '${items.length} shown',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        child: Column(
          children: [
            for (final item in items) ...[
              _InboxCard(
                item: item,
                selected: selectedRequestId == item.requestId,
                onTap: () => onSelect(item.requestId),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      );
    }

    return VenuePageSection(
      title: 'Review inbox',
      trailing: Text(
        '${items.length} shown',
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
            DataColumn(label: Text('Trail')),
            DataColumn(label: Text('Stop')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Updated')),
            DataColumn(label: Text('Revision')),
            DataColumn(label: Text('Review')),
          ],
          rows: [
            for (final item in items)
              DataRow(
                selected: selectedRequestId == item.requestId,
                onSelectChanged: (_) => onSelect(item.requestId),
                cells: [
                  DataCell(Text(item.venueName)),
                  DataCell(Text(item.trailName)),
                  DataCell(Text(item.stopLabel)),
                  DataCell(_StatusChip(item: item)),
                  DataCell(Text(_formatDate(item.updatedAt))),
                  DataCell(Text('v${item.revision}')),
                  DataCell(
                    TextButton(
                      onPressed: () => onSelect(item.requestId),
                      child: Text(item.primaryActionLabel),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminTrailParticipationInboxItemPresentation item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryPurple.withValues(alpha: 0.16)
          : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.venueName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.trailName,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _StatusChip(item: item),
                  Chip(label: Text(item.stopLabel)),
                  if (item.wasResubmitted)
                    const Chip(label: Text('Resubmitted')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item});

  final AdminTrailParticipationInboxItemPresentation item;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(item.statusLabel),
      backgroundColor: adminTrailParticipationStatusColor(
        item.displayStatus,
      ).withValues(alpha: 0.18),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.detail,
    required this.loading,
    required this.busy,
    required this.canManage,
    required this.conflictMessage,
    this.onRefresh,
    this.onRequestInformation,
    this.onApprove,
    this.onReject,
  });

  final AdminTrailParticipationRequestDetailPresentation? detail;
  final bool loading;
  final bool busy;
  final bool canManage;
  final String? conflictMessage;
  final VoidCallback? onRefresh;
  final VoidCallback? onRequestInformation;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const VenuePageSection(
        title: 'Request detail',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (detail == null) {
      return const VenuePageSection(
        title: 'Request detail',
        child: Text(
          'Select a request from the inbox to inspect venue, trail and audit history.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final item = detail!;
    final actions = item.actions
        .where(AdminTrailParticipationActionResolver.allowsDecision)
        .toList();

    return VenuePageSection(
      title: 'Request detail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (conflictMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                conflictMessage!,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (onRefresh != null)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh latest revision'),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _DetailRow(label: 'Venue', value: item.venueName),
          _DetailRow(label: 'Trail', value: item.trailName),
          _DetailRow(
            label: 'Requested stop',
            value: 'Stop ${item.requestedStopOrder}',
          ),
          _DetailRow(label: 'Status', value: item.statusLabel),
          _DetailRow(label: 'Revision', value: 'v${item.revision}'),
          if (item.submittedAt != null)
            _DetailRow(
              label: 'Submitted',
              value: _formatDate(item.submittedAt!),
            ),
          _DetailRow(label: 'Updated', value: _formatDate(item.updatedAt)),
          if (item.wasResubmitted)
            const _DetailRow(label: 'Resubmitted', value: 'Yes'),
          if (item.informationRequestNote?.isNotEmpty == true)
            _DetailRow(
              label: 'Information request',
              value: item.informationRequestNote!,
            ),
          if (item.decisionReason?.isNotEmpty == true)
            _DetailRow(label: 'Previous decision', value: item.decisionReason!),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Participation note',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.participationNote.isEmpty ? '—' : item.participationNote,
            style: const TextStyle(color: AppColors.white),
          ),
          if (item.eligibilityWarnings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Validation warnings',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final warning in item.eligibilityWarnings)
              Text('• $warning', style: const TextStyle(color: AppColors.white)),
          ],
          if (item.approvalPlan != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ApprovalPlanSummary(plan: item.approvalPlan!),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Audit timeline',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (item.auditTimeline.isEmpty)
            const Text(
              'No audit history is available.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            Column(
              children: [
                for (final entry in item.auditTimeline)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      entry.displayAction,
                      style: const TextStyle(color: AppColors.white),
                    ),
                    subtitle: Text(
                      '${_formatDate(entry.timestamp)} · ${entry.actorLabel}'
                      '${entry.note == null ? '' : '\n${entry.note}'}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: entry.revision == null
                        ? null
                        : Text(
                            'v${entry.revision}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (actions.contains(AdminTrailParticipationAction.requestInformation))
                OutlinedButton(
                  onPressed: busy || !canManage ? null : onRequestInformation,
                  child: Text(
                    canManage
                        ? 'Request information'
                        : kAdminPermissionDeniedTooltip,
                  ),
                ),
              if (actions.contains(AdminTrailParticipationAction.approve))
                FilledButton(
                  onPressed: busy || !canManage ? null : onApprove,
                  child: Text(
                    canManage ? 'Approve' : kAdminPermissionDeniedTooltip,
                  ),
                ),
              if (actions.contains(AdminTrailParticipationAction.reject))
                OutlinedButton(
                  onPressed: busy || !canManage ? null : onReject,
                  child: Text(
                    canManage ? 'Reject' : kAdminPermissionDeniedTooltip,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

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
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalPlanSummary extends StatelessWidget {
  const _ApprovalPlanSummary({required this.plan});

  final AdminTrailParticipationApprovalPlanPresentation plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approval placement plan',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            plan.trailWillBeMutated
                ? 'Approval would place the venue on the trail automatically.'
                : 'Approval records the workflow decision only. Trail stops are not changed automatically.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Proposed stop ${plan.proposedInsertionOrder}',
            style: const TextStyle(color: AppColors.white),
          ),
          if (plan.requiresManualPlacement)
            const Text(
              'Manual trail placement is required after approval.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          for (final warning in plan.conflictWarnings)
            Text('• $warning', style: const TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }
}

class _ApprovalConfirmationDialog extends StatelessWidget {
  const _ApprovalConfirmationDialog({required this.detail});

  final AdminTrailParticipationRequestDetailPresentation detail;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text(
        'Approve participation request?',
        style: TextStyle(color: AppColors.white),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow(label: 'Venue', value: detail.venueName),
            _DetailRow(label: 'Trail', value: detail.trailName),
            _DetailRow(
              label: 'Requested stop',
              value: 'Stop ${detail.requestedStopOrder}',
            ),
            _DetailRow(label: 'Revision', value: 'v${detail.revision}'),
            if (detail.eligibilityWarnings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Validation warnings',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              for (final warning in detail.eligibilityWarnings)
                Text('• $warning', style: const TextStyle(color: AppColors.white)),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              detail.approvalPlan?.trailWillBeMutated ?? false
                  ? 'The trail configuration will be updated when approval executes.'
                  : 'This approval records the workflow decision only. The venue will not be placed on the trail automatically.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}
