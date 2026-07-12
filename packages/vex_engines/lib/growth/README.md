# Growth Engine

## Intended responsibility

Version 1.5+ commercial and growth decision engine:

- boost product catalog and activation lifecycle rules
- subscription upgrade/downgrade/renewal/trial recommendations
- campaign readiness, health, completion, scoring, and recommendations
- commercial performance interpretation (not raw analytics calculation)
- marketing, ROI, conversion, and commercial summaries
- growth scoring, opportunity ranking, and owner-facing summaries
- boost renewal, expiry, duration, plan, and timing suggestions

## May depend on

- Adapter-supplied engagement counts and entitlement **flags** (not VexCore imports in engine core)
- Engine-neutral value objects in `domain/` and `shared/`

## Must not contain

- Flutter UI imports
- Firebase SDK imports
- Stripe SDK imports
- Raw Firestore paths in domain or application layers
- Entitlement matrix evaluation (VexCore)
- Analytics aggregation (Analytics Engine)
- Discovery ranking (Discovery Engine)

## Application services

| Service | Responsibility |
| --- | --- |
| `GrowthBoostService` | Boost activation, expiry, checkout validation |
| `GrowthBoostLifecycleService` | Renewal/expiry recommendations, suggested plans and timing |
| `GrowthSubscriptionService` | Upgrade/downgrade/renewal/trial, product summaries |
| `GrowthCampaignLifecycleService` | Campaign health, completion, scoring, recommendations |
| `GrowthMarketingSummaryService` | Marketing, ROI, conversion summaries |
| `GrowthCommercialService` | Pricing interpretation, forecasting, renewal prompts |
| `GrowthPerformanceInterpretationService` | Estimated visits/revenue, ROI signals |
| `GrowthScoringService` | Composite and multi-dimensional venue scores |
| `GrowthRecommendationService` | Ranked growth opportunities |
| `GrowthSummaryService` | Owner dashboard commercial summary composition |

## Migration status

| Phase | Status | Notes |
| --- | --- | --- |
| 0 — Structure | Complete | Folders, README, migration plan |
| 1 — Pure rules batch | Complete | Catalog, boost lifecycle, ROI interpretation |
| 2 — Commercial services | Complete | Subscriptions, campaigns, summaries, scoring |
| 3 — Admin/marketing UI wiring | In progress | Web marketing/subscription/analytics commercial sections wired via `GrowthCommercialViewSupport` |

**Completion: ~92%**

## Runtime flow

```text
UI / Widget
  → GrowthCommercialSupport / MobileGrowthCommercialSupport (adapter facade)
  → Growth Engine service (pure in-memory rules)
  → Firestore / Stripe adapter (unchanged I/O)
```

Network calls unchanged — adapters retain all I/O.
