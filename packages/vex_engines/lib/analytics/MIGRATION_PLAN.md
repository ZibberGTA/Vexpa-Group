# Analytics Engine — Migration Plan

Status: **Phase 4 complete — web and mobile aggregation wired**

## Classification key

| Tag | Meaning |
| --- | --- |
| **ANALYTICS** | Analytics Engine |
| **VC** | VexCore |
| **WEB** | Web app shell / Firebase adapters |
| **MOB** | Mobile app shell |
| **DISC** | Discovery Engine (consumes trending inputs) |
| **ADMIN** | Admin shell |

---

## Web audit (`apps/nightlife_web`)

| Path | Tag | Batch | Notes |
| --- | --- | --- | --- |
| `venue_management/data/venue_analytics_service.dart` | WEB/ANALYTICS | Wired | Firebase reads stay; engine composes results |
| `venue_management/data/venue_dashboard_repository.dart` | WEB/VE | Wired | Firebase reads stay; Venue + Analytics engines compose home data |
| `venue_management/data/venue_activity_service.dart` | WEB/ANALYTICS/VE | Wired | Firebase reads stay; engines aggregate and interpret |
| `venue_management/models/venue_dashboard_date_range.dart` | WEB/ANALYTICS | Wired | Delegates period boundaries to `AnalyticsDashboardPeriodCalculator` |
| `venue_management/models/venue_profile_views_chart_data.dart` | WEB | — | Chart point DTO + mock data |
| `test/venue_dashboard_main_content_test.dart` | WEB | — | Empty analytics parity |
| `test/analytics_engine_delegation_test.dart` | WEB | Added | Engine delegation |
| `test/venue_dashboard_engine_delegation_test.dart` | WEB | Added | Dashboard + activity delegation |

## Mobile audit (`apps/nightlife_app`)

| Path | Tag | Batch | Notes |
| --- | --- | --- | --- |
| `features/analytics/services/analytics_service.dart` | MOB/ANALYTICS | Wired | Log writes + reads; engine aggregates |
| `features/analytics/widgets/venue_analytics_card.dart` | MOB | — | UI shell |
| `features/owner/screens/owner_analytics_dashboard_screen.dart` | MOB | — | UI shell |
| `features/trending/services/trending_service.dart` | DISC | — | Consumes `AnalyticsSummary.venueViews` |

## VexCore

| Path | Tag | Notes |
| --- | --- | --- |
| `StaffPermission.analyticsView` | VC | Permission only |
| Analytics read contracts | VC | **Not yet created** — future Phase 5 |

---

## Batch 1 — Shared rules (complete)

| Source | Target | Notes |
| --- | --- | --- |
| `VenueAnalyticsService.percentChange` | **ANALYTICS** `AnalyticsPercentChange` | |
| Dashboard count assembly | **ANALYTICS** `AnalyticsMetricsComposer` | |
| Chart bucket labels | **ANALYTICS** `AnalyticsTimeBucketService` | |
| Profile views time series | **ANALYTICS** `AnalyticsChartSeriesBuilder` | |
| Top entity parsing (web + mobile) | **ANALYTICS** `AnalyticsTopEntityAggregator` | |
| Weekly growth (mobile) | **ANALYTICS** `AnalyticsWeeklyGrowthCalculator` | |
| Favourite conversion (mobile) | **ANALYTICS** `AnalyticsEngagementCalculator` | |

## Performance before and after

| Path | Reads | Writes | Listeners |
| --- | --- | --- | --- |
| Web dashboard snapshot | 5–7 counts + 1 get | 0 | 0 |
| Mobile venue summary | 6 counts + optional gets | 0 | 0 |
| Event logging | 0 | 1 add | 0 |

Engine adds in-memory composition only — query count unchanged.

## Rollback path

1. Revert web/mobile service delegation commits.
2. Restore inline aggregation in `venue_analytics_service.dart` and `analytics_service.dart`.
3. Remove `vex_engines` analytics exports.

No Firebase Rules or schema changes required.

## Remaining work

| Item | Tag | Notes |
| --- | --- | --- |
| VexCore `VenueAnalyticsDataService` | VC | Optional read contract pilot |
| Admin CRM analytics panels | ADMIN | Stay in admin shell |
| Discovery trending input wiring | DISC/ANALYTICS | Optional direct engine feed |
| AI / market intelligence | ANALYTICS | Future placeholders only |
