import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/services/auth_service.dart';
import '../../../auth/services/user_role_service.dart';
import '../../data/venue_dashboard_repository.dart';
import '../../data/venue_trail_participation_repository.dart';
import '../../models/venue_trail_participation_presentation.dart';
import '../../services/venue_trail_participation_action_resolver.dart';
import '../../services/venue_trail_participation_flow_handler.dart';
import '../../services/venue_trail_participation_presentation_mapper.dart';
import '../venue_dashboard_error_panel.dart';
import 'venue_trails_management_page.dart';

/// Loads live trail participation data for the venue trails workspace.
class VenueTrailsManagementConnectedPage extends StatefulWidget {
  const VenueTrailsManagementConnectedPage({
    super.key,
    this.repository,
    this.dashboardRepository,
  });

  final VenueTrailParticipationRepository? repository;
  final VenueDashboardRepository? dashboardRepository;

  @override
  State<VenueTrailsManagementConnectedPage> createState() =>
      _VenueTrailsManagementConnectedPageState();
}

class _VenueTrailsManagementConnectedPageState
    extends State<VenueTrailsManagementConnectedPage> {
  late final VenueTrailParticipationRepository _repository =
      widget.repository ?? VenueTrailParticipationRepository();
  late final VenueDashboardRepository _dashboardRepository =
      widget.dashboardRepository ?? VenueDashboardRepository();

  VenueTrailParticipationWorkspacePresentation? _workspace;
  VenueTrailParticipationFlowHandler? _flowHandler;
  String? _busyRequestId;
  String? _highlightedRequestId;
  String? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh({String? highlightedRequestId}) async {
    setState(() {
      _loading = _workspace == null;
      _loadError = null;
    });

    final user = AuthService.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _loadError = 'Sign in to manage trail participation.';
      });
      return;
    }

    final roleProfile = await UserRoleService.getCurrentUserProfile();
    final dashboardContext = await _dashboardRepository.resolveContext(
      user: user,
      roleProfile: roleProfile,
    );

    final workspace = await _repository.loadWorkspace(
      user: user,
      context: dashboardContext,
    );

    if (!mounted) return;

    if (!workspace.ok) {
      setState(() {
        _loading = false;
        _loadError =
            workspace.errorMessage ?? 'Unable to load trail participation.';
      });
      return;
    }

    final flowHandler = VenueTrailParticipationFlowHandler(
      repository: _repository,
      user: user,
      context: dashboardContext,
      onWorkspaceChanged: (highlightId) async {
        await _refresh(highlightedRequestId: highlightId);
      },
      onBusyRequestChanged: (requestId) {
        if (!mounted) return;
        setState(() => _busyRequestId = requestId);
      },
      showMessage: _showMessage,
    );

    setState(() {
      _workspace = workspace;
      _flowHandler = flowHandler;
      _loading = false;
      _highlightedRequestId = highlightedRequestId;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : null,
      ),
    );
  }

  VenueTrailEligiblePresentation? _eligibleByTrailId(String trailId) {
    final eligible = _workspace?.eligible ?? const [];
    for (final item in eligible) {
      if (item.trail.trailId == trailId) return item;
    }
    return null;
  }

  Future<void> _onDiscoveryJoin(String trailId) async {
    final eligible = _eligibleByTrailId(trailId);
    final handler = _flowHandler;
    if (eligible == null || handler == null) return;

    if (eligible.venueState == VenueTrailEligibleVenueState.requestPending &&
        eligible.existingApplication != null) {
      await handler.viewExistingApplication(context, eligible);
      return;
    }

    await handler.applyToTrail(context, eligible);
  }

  Future<void> _onApplicationPrimary(
    VenueTrailParticipationApplicationPresentation application,
  ) async {
    final action =
        application.primaryAction ?? VenueTrailParticipationAction.view;
    await _flowHandler?.handleApplicationAction(context, application, action);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _workspace == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return VenueDashboardErrorPanel(
        embedded: true,
        message: _loadError!,
        onRetry: () => _refresh(),
      );
    }

    final workspace = _workspace!;
    final discovery =
        VenueTrailParticipationPresentationMapper.mapEligibleTrails(
          workspace.eligible,
        );
    final participation =
        VenueTrailParticipationPresentationMapper.mapApplications(
          workspace.applications,
        );
    final opportunities =
        VenueTrailParticipationPresentationMapper.mapOpportunities(
          workspace.eligible,
        );

    return Stack(
      children: [
        VenueTrailsManagementPage(
          discoveryTrails: discovery,
          participationTrails: participation,
          opportunityTrails: opportunities,
          liveApplications: workspace.applications,
          eligibleTrails: workspace.eligible,
          highlightedRequestId: _highlightedRequestId,
          busyParticipationRequestId: _busyRequestId,
          onDiscoveryJoin: _onDiscoveryJoin,
          onOpportunityJoin: _onDiscoveryJoin,
          onApplicationPrimaryAction: _onApplicationPrimary,
        ),
        if (_loading)
          const Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}
