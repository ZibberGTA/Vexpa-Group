import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vex_engines/trail/application/trail_application_result.dart';
import 'package:vex_engines/trail/domain/participation/trail_participation_application.dart';

import '../data/venue_trail_participation_repository.dart';
import '../models/venue_dashboard_context.dart';
import '../models/venue_trail_participation_presentation.dart';
import 'venue_trail_participation_action_resolver.dart';
import '../widgets/trails/participation/trail_participation_application_form_dialog.dart';
import '../widgets/trails/participation/trail_participation_detail_dialog.dart';
import '../widgets/trails/participation/trail_participation_withdraw_dialog.dart';

/// Orchestrates venue trail participation UI actions through the repository.
class VenueTrailParticipationFlowHandler {
  VenueTrailParticipationFlowHandler({
    required this.repository,
    required this.user,
    required this.context,
    required this.onWorkspaceChanged,
    required this.onBusyRequestChanged,
    required this.showMessage,
  });

  final VenueTrailParticipationRepository repository;
  final User user;
  final VenueDashboardContext context;
  final Future<void> Function(String? highlightedRequestId) onWorkspaceChanged;
  final void Function(String? requestId) onBusyRequestChanged;
  final void Function(String message, {bool isError}) showMessage;

  String? _busyRequestId;
  bool get isBusy => _busyRequestId != null;

  Future<void> applyToTrail(
    BuildContext buildContext,
    VenueTrailEligiblePresentation eligible,
  ) async {
    if (_busyRequestId != null) return;

    if (!eligible.eligible) {
      showMessage(
        eligible.blockingReasons.isEmpty
            ? 'This trail is not accepting applications right now.'
            : eligible.blockingReasons.join('. '),
        isError: true,
      );
      return;
    }

    final positions = eligible.validStopPositions;
    if (positions.isEmpty) {
      showMessage(
        'No stop positions are available on this trail.',
        isError: true,
      );
      return;
    }

    final formResult = await TrailParticipationApplicationFormDialog.show(
      buildContext,
      trail: eligible.trail,
      validStopPositions: positions,
      mode: TrailParticipationFormMode.create,
      initialStopOrder: eligible.suggestedStopPosition,
    );
    if (formResult == null || !buildContext.mounted) return;

    final requestId = repository.generateRequestId();
    _setBusy(requestId);

    try {
      if (formResult.submit) {
        final result = await repository.createAndSubmitApplication(
          user: user,
          context: this.context,
          trailId: eligible.trail.trailId,
          requestedStopOrder: formResult.stopOrder,
          participationNote: formResult.note,
          requestId: requestId,
        );
        await _handleMutationResult(
          buildContext,
          result: result,
          successMessage: 'Application submitted.',
          highlightRequestId: requestId,
        );
      } else {
        final result = await repository.saveDraft(
          user: user,
          context: this.context,
          trailId: eligible.trail.trailId,
          requestedStopOrder: formResult.stopOrder,
          participationNote: formResult.note,
          requestId: requestId,
        );
        await _handleMutationResult(
          buildContext,
          result: result,
          successMessage: 'Draft saved.',
          highlightRequestId: requestId,
        );
      }
    } finally {
      _setBusy(null);
    }
  }

  Future<void> handleApplicationAction(
    BuildContext buildContext,
    VenueTrailParticipationApplicationPresentation application,
    VenueTrailParticipationAction action,
  ) async {
    if (_busyRequestId != null) return;

    switch (action) {
      case VenueTrailParticipationAction.view:
        await viewApplication(buildContext, application);
      case VenueTrailParticipationAction.editDraft:
        await editDraft(buildContext, application);
      case VenueTrailParticipationAction.submit:
        await submitDraft(buildContext, application);
      case VenueTrailParticipationAction.respond:
      case VenueTrailParticipationAction.resubmit:
        await respondToInformationRequest(buildContext, application);
      case VenueTrailParticipationAction.withdraw:
        await withdraw(buildContext, application);
      case VenueTrailParticipationAction.reapply:
        await reapply(buildContext, application);
    }
  }

  Future<void> viewApplication(
    BuildContext buildContext,
    VenueTrailParticipationApplicationPresentation application,
  ) async {
    _setBusy(application.requestId);
    try {
      final detail = await repository.loadApplicationDetail(
        user: user,
        context: context,
        requestId: application.requestId,
      );
      if (!buildContext.mounted) return;
      await TrailParticipationDetailDialog.show(
        buildContext,
        application: detail,
        onAction: (action) =>
            handleApplicationAction(buildContext, detail, action),
        busy: isBusy,
      );
    } on VenueTrailParticipationException catch (error) {
      showMessage(error.message, isError: true);
    } finally {
      _setBusy(null);
    }
  }

  Future<void> viewExistingApplication(
    BuildContext buildContext,
    VenueTrailEligiblePresentation eligible,
  ) async {
    final existing = eligible.existingApplication;
    if (existing == null) return;
    await handleApplicationAction(
      buildContext,
      existing,
      existing.primaryAction ?? VenueTrailParticipationAction.view,
    );
  }

  Future<void> editDraft(
    BuildContext buildContext,
    VenueTrailParticipationApplicationPresentation application,
  ) async {
    final positions = _positionsFor(application);
    final formResult = await TrailParticipationApplicationFormDialog.show(
      buildContext,
      trail: _trailDisplay(application),
      validStopPositions: positions,
      mode: TrailParticipationFormMode.editDraft,
      initialStopOrder: application.requestedStopOrder,
      initialNote: application.participationNote,
      allowSaveDraft: false,
    );
    if (formResult == null || !buildContext.mounted) return;

    _setBusy(application.requestId);
    try {
      final domain = await _loadDomainApplication(application.requestId);
      if (domain == null) return;

      TrailApplicationResult<TrailParticipationApplication> result;
      if (formResult.submit) {
        result = await repository.updateDraft(
          user: user,
          context: context,
          application: domain,
          requestedStopOrder: formResult.stopOrder,
          participationNote: formResult.note,
        );
        if (result case TrailApplicationSuccess(value: final updated)) {
          result = await repository.submitDraft(
            user: user,
            context: context,
            application: updated,
          );
        }
      } else {
        result = await repository.updateDraft(
          user: user,
          context: context,
          application: domain,
          requestedStopOrder: formResult.stopOrder,
          participationNote: formResult.note,
        );
      }

      await _handleMutationResult(
        buildContext,
        result: result,
        successMessage: formResult.submit
            ? 'Application submitted.'
            : 'Draft updated.',
        highlightRequestId: application.requestId,
      );
    } finally {
      _setBusy(null);
    }
  }

  Future<void> submitDraft(
    BuildContext buildContext,
    VenueTrailParticipationApplicationPresentation application,
  ) async {
    _setBusy(application.requestId);
    try {
      final domain = await _loadDomainApplication(application.requestId);
      if (domain == null) return;

      final result = await repository.submitDraft(
        user: user,
        context: context,
        application: domain,
      );
      await _handleMutationResult(
        buildContext,
        result: result,
        successMessage: 'Application submitted.',
        highlightRequestId: application.requestId,
      );
    } finally {
      _setBusy(null);
    }
  }

  Future<void> respondToInformationRequest(
    BuildContext buildContext,
    VenueTrailParticipationApplicationPresentation application,
  ) async {
    final positions = _positionsFor(application);
    final formResult = await TrailParticipationApplicationFormDialog.show(
      buildContext,
      trail: _trailDisplay(application),
      validStopPositions: positions,
      mode: TrailParticipationFormMode.respondToInformationRequest,
      initialStopOrder: application.requestedStopOrder,
      initialNote: application.participationNote,
      allowSaveDraft: false,
    );
    if (formResult == null || !formResult.submit || !buildContext.mounted) {
      return;
    }

    _setBusy(application.requestId);
    try {
      final domain = await _loadDomainApplication(application.requestId);
      if (domain == null) return;

      final result = await repository.resubmitApplication(
        user: user,
        context: context,
        application: domain,
        requestedStopOrder: formResult.stopOrder,
        participationNote: formResult.note,
      );
      await _handleMutationResult(
        buildContext,
        result: result,
        successMessage: 'Application resubmitted.',
        highlightRequestId: application.requestId,
      );
    } finally {
      _setBusy(null);
    }
  }

  Future<void> withdraw(
    BuildContext buildContext,
    VenueTrailParticipationApplicationPresentation application,
  ) async {
    final confirmed = await TrailParticipationWithdrawDialog.show(
      buildContext,
      trailName: application.trailName,
    );
    if (!confirmed || !buildContext.mounted) return;

    _setBusy(application.requestId);
    try {
      final domain = await _loadDomainApplication(application.requestId);
      if (domain == null) return;

      final result = await repository.withdrawApplication(
        user: user,
        context: context,
        application: domain,
      );
      await _handleMutationResult(
        buildContext,
        result: result,
        successMessage: 'Application withdrawn.',
        highlightRequestId: application.requestId,
      );
    } finally {
      _setBusy(null);
    }
  }

  Future<void> reapply(
    BuildContext buildContext,
    VenueTrailParticipationApplicationPresentation application,
  ) async {
    final eligible = VenueTrailEligiblePresentation(
      trail: _trailDisplay(application),
      eligible: true,
      blockingReasons: const [],
      validStopPositions: _positionsFor(application),
      suggestedStopPosition: application.requestedStopOrder,
      venueState: VenueTrailEligibleVenueState.eligible,
    );
    await applyToTrail(buildContext, eligible);
  }

  Future<TrailParticipationApplication?> _loadDomainApplication(
    String requestId,
  ) async {
    return repository.getApplicationForMutation(requestId);
  }

  VenueTrailDisplayPresentation _trailDisplay(
    VenueTrailParticipationApplicationPresentation application,
  ) {
    return VenueTrailDisplayPresentation(
      trailId: application.trailId,
      name: application.trailName,
      description: application.trailDescription,
      bannerImageUrl: application.trailBannerUrl,
      stopCount: application.trailStopCount,
      maximumStops: application.trailMaximumStops,
      participationInstructions: application.trailParticipationInstructions,
      applicationWindowLabel: application.trailApplicationWindowLabel,
    );
  }

  List<int> _positionsFor(
    VenueTrailParticipationApplicationPresentation application,
  ) {
    if (!application.venueSelectableStopPosition) {
      return [application.requestedStopOrder];
    }
    final max = application.trailMaximumStops ?? application.trailStopCount + 1;
    final positions = <int>[];
    for (var i = 1; i <= max; i++) {
      positions.add(i);
    }
    if (positions.isEmpty) positions.add(application.requestedStopOrder);
    return positions;
  }

  Future<void> _handleMutationResult(
    BuildContext buildContext, {
    required TrailApplicationResult<TrailParticipationApplication> result,
    required String successMessage,
    required String highlightRequestId,
  }) async {
    if (result case TrailApplicationFailure(:final code, :final message)) {
      final revisionConflict =
          code.contains('revision') ||
          message.toLowerCase().contains('revision');
      showMessage(
        revisionConflict
            ? 'This application was updated elsewhere. Refresh and try again.'
            : message,
        isError: true,
      );
      if (revisionConflict) {
        await onWorkspaceChanged(null);
      }
      return;
    }

    showMessage(successMessage);
    await onWorkspaceChanged(highlightRequestId);
  }

  void _setBusy(String? requestId) {
    _busyRequestId = requestId;
    onBusyRequestChanged(requestId);
  }
}
