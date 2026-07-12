# Growth Engine — Migration Plan

Status: **Phase 2 complete — commercial services and adapter facades**

## Classification key

| Tag | Meaning |
| --- | --- |
| **GROWTH** | Growth Engine |
| **VC** | VexCore |
| **WEB** | Web app shell / Firebase adapters |
| **MOB** | Mobile app shell |
| **BILLING** | Stripe / checkout adapters |
| **ANALYTICS** | Analytics Engine |
| **DISCOVERY** | Discovery Engine |

---

## Phase 1 migrated (complete)

Catalog, boost lifecycle, ROI interpretation, upgrade recommendations, campaign readiness, comparisons, scoring, summaries.

---

## Phase 2 migrated (complete)

| Source | Target | Notes |
| --- | --- | --- |
| Subscription upgrade logic | **GROWTH** `GrowthSubscriptionService` | Upgrade/downgrade/renewal/trial |
| Plan comparisons | **GROWTH** | Product summaries, deterministic ordering |
| Campaign readiness | **GROWTH** `GrowthCampaignLifecycleService` | Health, completion, scoring |
| Marketing metrics interpretation | **GROWTH** `GrowthMarketingSummaryService` | ROI, conversion, performance |
| Pricing / forecasting | **GROWTH** `GrowthCommercialService` | Renewal prompts, revenue forecast |
| Boost renewal suggestions | **GROWTH** `GrowthBoostLifecycleService` | Plan, duration, timing |
| Venue growth scores | **GROWTH** `GrowthScoringService.venueScores` | Growth/commercial/marketing/revenue |
| Web `GrowthCommercialSupport` | **WEB** | Expanded facade |
| Mobile `MobileGrowthCommercialSupport` | **MOB** | New facade |
| Mobile analytics card ROI | **MOB** | Delegates via facade |

Status: **Phase 3 in progress — web commercial UI wired to engine summaries**

## Phase 3 migrated (in progress)

| Source | Target | Notes |
| --- | --- | --- |
| `venue_management_tab_pages.dart` subscription tab | **WEB** `GrowthCommercialViewSupport` | Catalog plan cards, renewal prompts, recommendations |
| `venue_management_tab_pages.dart` marketing tab | **WEB** | Campaign summaries, performance, forecasts |
| Analytics marketing insights + goals | **WEB** | Engine recommendations and growth goals |
| `venue_dashboard_go_premium_panel.dart` | **WEB** | Upgrade recommendation copy from engine |

## Remaining in adapters (Phase 3)

| Path | Tag | Notes |
| --- | --- | --- |
| `boost_service.dart` | MOB/BILLING | Firestore writes, streams, revenue queries |
| `subscription_service.dart` | MOB/BILLING | Stripe reads, checkout, portal |
| `venue_management_tab_pages.dart` marketing UI | WEB | ~~Mock data~~ — subscription/marketing/commercial sections wired |
| `DiscoveryBoostEvaluator` | DISCOVERY | Ranking input evaluation stays in Discovery |

## Performance before and after Phase 2

| Path | Firestore | Stripe | Change |
| --- | --- | --- | --- |
| Boost activate | 2 writes | 0 | Unchanged |
| Analytics card | same reads | 0 | Unchanged |
| Subscription pricing | 0 | 0 | Unchanged |

Phase 2 adds in-memory commercial decisioning only.
