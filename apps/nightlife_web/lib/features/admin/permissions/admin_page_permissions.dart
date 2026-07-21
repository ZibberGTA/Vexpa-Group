import '../models/admin_dashboard_models.dart';
import 'permission_service.dart';
import 'staff_permission.dart';

/// Maps admin dashboard pages and row actions to [StaffPermission] values.
class AdminPagePermissions {
  AdminPagePermissions._();

  static StaffPermission? viewPermission(AdminDashboardPage page) {
    return switch (page) {
      AdminDashboardPage.dashboard => StaffPermission.dashboardView,
      AdminDashboardPage.users => StaffPermission.usersView,
      AdminDashboardPage.venues => StaffPermission.venuesView,
      AdminDashboardPage.venueClaims => StaffPermission.venueClaimsView,
      AdminDashboardPage.teamMembers => StaffPermission.staffView,
      AdminDashboardPage.drinks => StaffPermission.drinksView,
      AdminDashboardPage.deals => StaffPermission.dealsView,
      AdminDashboardPage.events => StaffPermission.eventsView,
      AdminDashboardPage.trails ||
      AdminDashboardPage.trailParticipationReview => StaffPermission.trailsView,
      AdminDashboardPage.platformAnalytics => StaffPermission.analyticsView,
      AdminDashboardPage.searchIntelligence =>
        StaffPermission.searchIntelligenceView,
      AdminDashboardPage.venueIntelligence =>
        StaffPermission.venueIntelligenceView,
      AdminDashboardPage.reports => StaffPermission.reportsView,
      AdminDashboardPage.subscriptions => StaffPermission.subscriptionsView,
      AdminDashboardPage.payments => StaffPermission.paymentsView,
      AdminDashboardPage.auditLog => StaffPermission.auditView,
      AdminDashboardPage.applicationSettings ||
      AdminDashboardPage.subscriptionSettings ||
      AdminDashboardPage.categories ||
      AdminDashboardPage.branding => StaffPermission.systemSettings,
      AdminDashboardPage.developer ||
      AdminDashboardPage.systemHealth => StaffPermission.systemMonitoringView,
      AdminDashboardPage.adminMap => StaffPermission.adminMapView,
      AdminDashboardPage.reviews ||
      AdminDashboardPage.photos ||
      AdminDashboardPage.promotions ||
      AdminDashboardPage.supportTickets ||
      AdminDashboardPage.feedback ||
      AdminDashboardPage.notifications ||
      AdminDashboardPage.moderation => StaffPermission.reportsView,
    };
  }

  static StaffPermission? managePermission(AdminDashboardPage page) {
    return switch (page) {
      AdminDashboardPage.users => StaffPermission.usersEdit,
      AdminDashboardPage.venues => StaffPermission.venuesEdit,
      AdminDashboardPage.venueClaims => StaffPermission.venueClaimApprove,
      AdminDashboardPage.drinks => StaffPermission.drinksManage,
      AdminDashboardPage.deals => StaffPermission.dealsManage,
      AdminDashboardPage.events => StaffPermission.eventsManage,
      AdminDashboardPage.trails ||
      AdminDashboardPage.trailParticipationReview => StaffPermission.trailsManage,
      AdminDashboardPage.subscriptions => StaffPermission.subscriptionsManage,
      AdminDashboardPage.payments => StaffPermission.paymentsManage,
      AdminDashboardPage.platformAnalytics => StaffPermission.analyticsAdvanced,
      AdminDashboardPage.auditLog => StaffPermission.auditView,
      AdminDashboardPage.applicationSettings ||
      AdminDashboardPage.subscriptionSettings ||
      AdminDashboardPage.categories ||
      AdminDashboardPage.branding => StaffPermission.systemSettings,
      AdminDashboardPage.developer => StaffPermission.systemMonitoringView,
      AdminDashboardPage.reports => StaffPermission.reportsManage,
      AdminDashboardPage.moderation ||
      AdminDashboardPage.reviews ||
      AdminDashboardPage.photos => StaffPermission.reportsModerate,
      AdminDashboardPage.notifications =>
        StaffPermission.platformNotificationsManage,
      _ => null,
    };
  }

  static bool canViewPage(
    AdminDashboardPage page,
    PermissionService permissions,
  ) {
    final required = viewPermission(page);
    if (required == null) return true;
    return permissions.has(required);
  }

  static bool isNavLocked(
    AdminDashboardPage page,
    PermissionService permissions,
  ) {
    return !canViewPage(page, permissions);
  }

  static bool canPerformAction(
    AdminDashboardPage page,
    String action,
    PermissionService permissions,
  ) {
    final permission = actionPermission(page, action);
    if (permission == null) return true;
    return permissions.has(permission);
  }

  static StaffPermission? actionPermission(
    AdminDashboardPage page,
    String action,
  ) {
    final normalized = action.trim().toLowerCase();

    if (page == AdminDashboardPage.teamMembers) {
      return switch (normalized) {
        _ when normalized.contains('view') => StaffPermission.staffView,
        _ when normalized.contains('invite') => StaffPermission.staffInvite,
        _ when normalized.contains('role') => StaffPermission.staffRoleChange,
        _ when normalized.contains('remove') => StaffPermission.staffRemove,
        _ => StaffPermission.staffEdit,
      };
    }

    if (page == AdminDashboardPage.users) {
      return switch (normalized) {
        'view user' => StaffPermission.usersView,
        'suspend' || 'unsuspend' => StaffPermission.usersSuspend,
        'ban' || 'change role' => StaffPermission.usersEdit,
        _ when normalized.contains('delete') => StaffPermission.usersDelete,
        _ => StaffPermission.usersEdit,
      };
    }

    if (page == AdminDashboardPage.venueClaims) {
      return switch (normalized) {
        'approve' ||
        'reject' ||
        'request more information' => StaffPermission.venueClaimApprove,
        'assign reviewer' => StaffPermission.venueClaimAssign,
        'open venue profile' => StaffPermission.venuesView,
        _ => StaffPermission.venueClaimApprove,
      };
    }

    if (page == AdminDashboardPage.venues) {
      return switch (normalized) {
        _ when normalized.contains('delete') => StaffPermission.venuesDelete,
        _ when normalized.contains('approve') => StaffPermission.venueApprove,
        _ => StaffPermission.venuesEdit,
      };
    }

    if (page == AdminDashboardPage.drinks) {
      return StaffPermission.drinksManage;
    }
    if (page == AdminDashboardPage.deals) {
      return StaffPermission.dealsManage;
    }
    if (page == AdminDashboardPage.events) {
      return StaffPermission.eventsManage;
    }
    if (page == AdminDashboardPage.trails ||
        page == AdminDashboardPage.trailParticipationReview) {
      return switch (normalized) {
        'view' => StaffPermission.trailsView,
        'request information' ||
        'request more information' => StaffPermission.trailsManage,
        'approve' => StaffPermission.trailsManage,
        'reject' => StaffPermission.trailsManage,
        _ => StaffPermission.trailsManage,
      };
    }
    if (page == AdminDashboardPage.subscriptions) {
      return StaffPermission.subscriptionsManage;
    }
    if (page == AdminDashboardPage.payments) {
      return StaffPermission.paymentsManage;
    }
    if (page == AdminDashboardPage.auditLog) {
      return StaffPermission.auditView;
    }

    return managePermission(page);
  }

  static String accessLabel(
    AdminDashboardPage page,
    PermissionService permissions,
  ) {
    if (!canViewPage(page, permissions)) return 'Restricted';
    final manage = managePermission(page);
    if (manage != null && permissions.has(manage)) return 'Manage';
    return 'View';
  }
}
