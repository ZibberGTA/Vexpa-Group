# Analytics Engine

## Intended responsibility

Version 1 launch engine for venue analytics that already exist today:

- venue and dashboard metrics
- page/profile views, saves, content views
- engagement and popularity calculations
- chart time-bucketing and aggregation
- top entity ranking
- weekly growth comparisons
- trending score inputs

Future-ready structure only (not implemented in Version 1):

- market intelligence
- predictive analytics
- AI insights

## May depend on

- VexCore contracts: permissions (`viewAnalytics`), observability, future analytics read services
- Engine-neutral value objects in `domain/` and `application/`

## Must not contain

- Flutter UI imports in `domain/`, `application/`, or `data/`
- Firebase SDK imports anywhere in the engine
- Raw Firestore collection paths in domain or application layers
- Discovery search orchestration (Discovery Engine)
- Claim workflows (Claim Engine)
- Growth campaigns (Growth Engine)

## Layer layout

```text
analytics/
  domain/          # event types, metrics DTOs, chart periods
  application/     # aggregation, engagement, chart series, validation
  data/            # future repository interfaces (reads stay in app adapters)
  shared/          # reserved for cross-layer helpers
  presentation/
    web/           # dashboard charts/widgets (later phase)
    mobile/        # owner analytics screens (later phase)
  tests/           # engine test documentation
```

## VexCore contract rule

Permissions and generic data contracts remain in VexCore. The Analytics Engine owns
**metric aggregation and business rules**. Firebase count/get adapters remain in
web and mobile app shells until VexCore analytics read contracts are introduced.

## Performance rule

Migrations must not add Firestore reads, writes, listeners, or extra aggregation
passes. Engine work composes adapter results in memory on existing query paths.

## Migration status

| Phase | Status | Notes |
| --- | --- | --- |
| 0 — Structure | Complete | Folder layout, README, migration plan |
| 1 — Shared rules batch | Complete | Metrics composer, percent change, chart buckets |
| 2 — Aggregation services | Complete | Top entities, weekly growth, engagement |
| 3 — Web runtime slice | Complete | `VenueAnalyticsService` dashboard snapshot |
| 4 — Mobile runtime slice | Complete | `AnalyticsService` summary and growth |
| 5 — VexCore read contracts | Planned | Optional `VenueAnalyticsDataService` |

## Runtime flow (Version 1)

```text
VenueDashboardRepository
  → VenueAnalyticsService (Firebase count/get — unchanged)
  → Analytics Engine (compose metrics, chart series, top entities)
  → dashboard UI
```

Network calls unchanged: same count/get queries per dashboard load.
