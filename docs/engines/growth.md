# Growth Engine

## Overview

Growth, promotion, subscriptions, boosts, onboarding nudges, and campaign workflows. Commercial **decision rules** live in `packages/vex_engines/lib/growth/`; Firebase, Firestore, and Stripe remain in app adapters.

## Purpose

Own **revenue growth mechanics** separately from Analytics (measurement) and Experience (content).

## Responsibilities

- Boost product catalog, activation rules, renewal/expiry recommendations
- Subscription upgrade/downgrade/renewal/trial recommendations
- Campaign readiness, health, completion, scoring
- Commercial performance interpretation (estimated visits/revenue, ROI signals)
- Marketing, ROI, conversion, and commercial summaries
- Multi-dimensional venue growth scores (growth, commercial, marketing, revenue)
- Revenue forecasting and pricing interpretation

## Version

**Version 1.5–2** — commercial services batch complete.

## Dependencies

- Adapter-supplied engagement counts and entitlement flags
- Analytics Engine: raw aggregates via adapters — Growth interprets, does not aggregate

## Current Status

**~92% complete**

| Phase | Status |
| --- | --- |
| Pure rules batch (catalog, boost, ROI) | Complete |
| Commercial services (Phase 2) | Complete |
| Marketing dashboard live data wiring | In progress — web subscription/marketing/analytics commercial sections wired |
| Stripe checkout adapter consolidation | Planned |

## Technical Notes

- Must not contain Firebase SDK imports or Flutter UI in engine core layers.
- Web facade: `GrowthCommercialSupport`
- Mobile facade: `MobileGrowthCommercialSupport`

## Outstanding Work

- Wire remaining analytics mock KPI sections (non-commercial) to Analytics Engine
- Mobile/web subscription checkout adapter consolidation
- Admin boost CRM interpretation

**Deep dive:** [packages/vex_engines/lib/growth/README.md](../../packages/vex_engines/lib/growth/README.md) · [MIGRATION_PLAN.md](../../packages/vex_engines/lib/growth/MIGRATION_PLAN.md)
