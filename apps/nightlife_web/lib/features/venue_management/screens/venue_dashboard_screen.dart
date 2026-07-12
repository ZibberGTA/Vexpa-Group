import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../auth/services/user_role_service.dart';
import '../../venues/models/venue_model.dart';
import '../data/venue_dashboard_repository.dart';
import '../models/venue_dashboard_context.dart';
import '../models/venue_dashboard_date_range.dart';
import '../models/venue_dashboard_home_data.dart';
import '../models/venue_dashboard_tab.dart';
import '../widgets/venue_dashboard_error_panel.dart';
import '../widgets/venue_dashboard_shell.dart';

/// Venue owner and employee dashboard — protected by [AuthGuard].
class VenueDashboardScreen extends StatefulWidget {
  const VenueDashboardScreen({
    super.key,
    this.initialTab,
  });

  final VenueDashboardTab? initialTab;

  @override
  State<VenueDashboardScreen> createState() => _VenueDashboardScreenState();
}

class _VenueDashboardScreenState extends State<VenueDashboardScreen> {
  final _repository = VenueDashboardRepository();

  VenueDashboardContext? _contextData;
  VenueModel? _activeVenue;
  VenueDashboardHomeData? _homeData;
  VenueDashboardDateRange _selectedRange = VenueDashboardDateRange.defaultRange;

  bool _loadingContext = true;
  bool _loadingHomeData = false;
  Object? _contextError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loadingContext = true;
      _contextError = null;
    });

    final user = AuthService.currentUser;
    if (user == null) {
      setState(() {
        _loadingContext = false;
        _contextError = VenueDashboardLoadException(
          'You must be signed in to manage a venue.',
        );
      });
      return;
    }

    try {
      final roleProfile = await UserRoleService.getCurrentUserProfile();
      final contextData = await _repository.resolveContext(
        user: user,
        roleProfile: roleProfile,
      );
      final venue = await _repository.loadVenue(contextData.venueId);
      if (venue == null) {
        throw VenueDashboardLoadException(
          'Your venue could not be loaded. Please try again.',
        );
      }

      if (!mounted) return;
      setState(() {
        _contextData = contextData.copyWith(
          subscriptionPlanId: venue.subscriptionPlanId,
        );
        _activeVenue = venue;
        _loadingContext = false;
      });

      await _loadHomeData(_selectedRange);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _contextError = error;
        _loadingContext = false;
      });
    }
  }

  Future<void> _loadHomeData(VenueDashboardDateRange range) async {
    final venue = _activeVenue;
    if (venue == null) return;

    setState(() {
      _loadingHomeData = true;
      _selectedRange = range;
    });

    try {
      final completion = await _repository.loadProfileCompletion(venue);
      final homeData = await _repository.loadHomeData(
        venue: venue,
        profileCompletion: completion,
        dateRange: range,
      );

      if (!mounted) return;
      setState(() {
        _homeData = homeData;
        _contextError = null;
        _loadingHomeData = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _homeData = VenueDashboardHomeData.empty(dateRange: range);
        _loadingHomeData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingContext) {
      return const VenueDashboardShell.loading();
    }

    if (_contextError != null || _contextData == null) {
      return VenueDashboardErrorPanel(
        message: _contextError is VenueDashboardLoadException
            ? (_contextError as VenueDashboardLoadException).message
            : 'We could not load your venue dashboard.',
        onRetry: _loadDashboard,
      );
    }

    return VenueDashboardShell(
      contextData: _contextData!,
      initialTab: widget.initialTab ?? VenueDashboardTab.dashboard,
      homeData: _homeData,
      isLoadingHomeData: _loadingHomeData,
      onRefreshHomeData: () => _loadHomeData(_selectedRange),
      onDateRangeChanged: _loadHomeData,
    );
  }
}
