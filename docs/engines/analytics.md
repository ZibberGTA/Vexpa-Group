# Analytics Engine

## Overview

Version 1 launch engine for **venue analytics that exist today**: dashboard metrics, engagement calculations, chart time-bucketing, top entity ranking, and weekly growth comparisons.

## Purpose

Centralise metric **aggregation rules** so web venue dashboards and mobile owner analytics share one implementation.

## Responsibilities

- Metrics composition from adapter-provided counts
- Percent change and weekly growth calculations
- Chart series bucketing (e.g. profile views by weekday)
- Top drinks/deals/events aggregation from event records
- Engagement and popularity scoring
- Trending score **inputs** (consumed by Discovery trending scorer)

Future-ready only (not V1): market intelligence, predictive analytics, AI insights.

## Version

**Version 1** — launch engine.

## Dependencies

- VexCore: permissions (`viewAnalytics`), observability; future analytics read service
- Discovery Engine: trending scorer consumes analytics-derived inputs — via adapter data, not private reads

## Uses VexCore Layers

| Layer | Usage |
| --- | --- |
| Permissions | Analytics access gating |
| Observability | Event records for aggregation |

## Owns

- Aggregation formulas and chart bucketing rules
- Analytics domain DTOs

## Consumes

- Count/get query results from Firebase adapters (unchanged query counts on migration)

## Provides

- `AnalyticsMetricsComposer`, `AnalyticsChartSeriesBuilder`, `AnalyticsTopEntityAggregator`, etc.
- Web: `VenueAnalyticsService` → dashboard snapshot
- Mobile: `AnalyticsService` summary and growth

## Current Status

**~75% complete**

| Phase | Status |
| --- | --- |
| Shared rules + aggregation | Complete |
| Web runtime slice | Complete |
| Mobile runtime slice | Complete |
| VexCore analytics read contracts | Planned |

Network: same count/get queries per dashboard load as before migration.

## Future Features

- `VenueAnalyticsDataService` in VexCore
- Intelligence Engine consumption of anonymised aggregates
- Presentation chart widgets under engine presentation folders

## Technical Notes

- Migrations must not add Firestore reads or extra aggregation passes.
- Package: `packages/vex_engines/lib/analytics/`

## Known Risks

- Analytics/intelligence privacy — identifiable tenant joins must be avoided ([09-risk-register.md](../vexcore/09-risk-register.md)).
- Dashboard and mobile may diverge if delegation tests lapse.

## Outstanding Work

- VexCore read contract pilot
- Presentation layer
- Formal Intelligence boundary when Version 2 begins

**Deep dive:** [packages/vex_engines/lib/analytics/README.md](../../packages/vex_engines/lib/analytics/README.md) · [MIGRATION_PLAN.md](../../packages/vex_engines/lib/analytics/MIGRATION_PLAN.md)
