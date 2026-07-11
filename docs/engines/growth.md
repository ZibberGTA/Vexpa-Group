# Growth Engine

## Overview

Growth, promotion, subscriptions, boosts, onboarding nudges, and campaign workflows. Partial logic exists today in **app monetisation services** (mobile boosts, subscription reads) — not yet extracted to the engine.

## Purpose

Own **revenue growth mechanics** separately from Analytics (measurement) and Experience (content).

## Responsibilities

(planned)

- Subscription tier entitlements and feature gating inputs to permissions
- Boost plans, activation rules, and expiry evaluation (partially in Discovery `DiscoveryBoostEvaluator` for ranking; Growth owns product/commerce semantics)
- Promotional campaigns and onboarding nudges
- Monetisation event preparation

## Version

**Version 1.5–2** — not a Version 1 launch engine.

## Dependencies

- VexCore: identity, permissions, configuration, integrations (Stripe), events, data access, observability
- Analytics Engine: campaign performance reads via aggregates — not private persistence

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Permissions | Entitlement-aware feature gates |
| Integrations | Stripe checkout and webhooks |
| Configuration | Plan definitions and feature flags |
| Events | Subscription changed, boost activated |

## Owns

(planned) Subscription entitlement rules, boost product definitions, campaign orchestration.

## Consumes

(planned) Venue and owner identity context; payment status from integration adapters.

## Provides

(planned) Entitlement context for Venue/Experience features; boost activation validation; web/mobile `SubscriptionService` facades.

## Current Status

**Placeholder** — README at `packages/vex_engines/lib/growth/`. Mobile `BoostService`, `SubscriptionService`; web venue subscription services contain logic to migrate.

## Future Features

- Unify mobile and web subscription entitlement ([07-duplication-audit.md](../vexcore/07-duplication-audit.md))
- Stripe enforcement beyond temporary wrappers
- Corporate tier rules

## Technical Notes

- Must not contain Firebase SDK imports or Flutter UI in engine core layers.
- Direct Firebase access forbidden — adapters only.

## Known Risks

- Duplicated subscription logic between mobile and web until migration completes.
- Entitlements incorrectly implemented in UI instead of permission evaluator.

## Outstanding Work

- Migration inventory from monetisation services
- Define entitlement DTOs and Growth application services
- ADR when Stripe enforcement scope is finalised

**Deep dive:** [packages/vex_engines/lib/growth/README.md](../../packages/vex_engines/lib/growth/README.md)
