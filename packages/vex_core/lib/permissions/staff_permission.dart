/// Strongly typed permissions for the Vexda internal admin platform.
enum StaffPermission {
  dashboardView,

  usersView,
  usersEdit,
  usersSuspend,
  usersDelete,

  venuesView,
  venuesEdit,
  venuesDelete,
  venueApprove,
  venueClaimsView,
  venueClaimApprove,
  venueClaimAssign,

  drinksView,
  drinksManage,

  dealsView,
  dealsManage,

  eventsView,
  eventsManage,

  trailsView,
  trailsManage,

  analyticsView,
  analyticsAdvanced,

  paymentsView,
  paymentsManage,

  subscriptionsView,
  subscriptionsManage,

  reportsView,
  reportsManage,
  reportsModerate,

  searchIntelligenceView,

  venueIntelligenceView,

  adminMapView,

  staffView,
  staffInvite,
  staffEdit,
  staffRemove,
  staffRoleChange,
  staffManageSuperAdmins,

  auditView,

  systemSettings,
  systemMonitoringView,
  platformNotificationsManage,

  financials,
}
