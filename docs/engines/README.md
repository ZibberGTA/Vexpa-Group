# Vexda Engine Catalogue

Business capability modules live in `packages/vex_engines/`. Each engine owns a **single clear home** for its domain rules. Engines consume **VexCore contracts**; they do not import Firebase SDKs or Flutter UI in domain/application/data layers.

## Version 1 launch engines

| Engine | Document | Package path | Status (approx.) |
| --- | --- | --- | --- |
| Venue | [venue.md](./venue.md) | `lib/venue/` | ~75% — helpers, domain rules, profile updates |
| Discovery | [discovery.md](./discovery.md) | `lib/discovery/` | ~88% — search, ranking, mobile/web consolidation |
| Experience | [experience.md](./experience.md) | `lib/experience/` | ~78% — drinks, deals, events business rules |
| Claim | [claim.md](./claim.md) | `lib/claim/` | ~70% — submission, review, scoring wired on web |
| Analytics | [analytics.md](./analytics.md) | `lib/analytics/` | ~75% — dashboard metrics web + mobile |

## Discovery-adjacent (Version 1 product, engine placeholder)

| Engine | Document | Package path | Status |
| --- | --- | --- | --- |
| Trail | [trail.md](./trail.md) | `lib/trail/` | Placeholder — trails in product/search; engine not migrated |

## Future engines (not Version 1)

| Engine | Document | Target version | Package path |
| --- | --- | --- | --- |
| Growth | [growth.md](./growth.md) | 1.5–2 | `lib/growth/` |
| Intelligence | [intelligence.md](./intelligence.md) | 2 | `lib/intelligence/` |
| Messaging | [messaging.md](./messaging.md) | 3 | *(planned — no package yet)* |
| Membership | [membership.md](./membership.md) | 3 | *(planned — no package yet)* |
| Booking | [booking.md](./booking.md) | 4 | *(planned — no package yet)* |
| Ticketing | [ticket.md](./ticket.md) | 4 | *(planned — no package yet)* |
| Ordering | [ordering.md](./ordering.md) | 4 | *(planned — no package yet)* |
| POS | [pos.md](./pos.md) | 4 | *(planned — no package yet)* |
| Distribution | [distribution.md](./distribution.md) | 4+ | *(planned — separate platform)* |

## Shared rules

- [Engine Acceptance Rule](../decisions/0005-engine-acceptance-rule.md) — definition of “engine complete”
- [Dependency rules](../vexcore/03-dependency-rules.md) — what engines may and may not import
- [VexCore layer boundaries](../vexcore/02-layer-boundaries.md) — infrastructure contracts engines consume

## Technical deep dives

| Engine | README | Migration plan |
| --- | --- | --- |
| Venue | [packages/vex_engines/lib/venue/README.md](../../packages/vex_engines/lib/venue/README.md) | [MIGRATION_PLAN.md](../../packages/vex_engines/lib/venue/MIGRATION_PLAN.md) |
| Discovery | [packages/vex_engines/lib/discovery/README.md](../../packages/vex_engines/lib/discovery/README.md) | [MIGRATION_PLAN.md](../../packages/vex_engines/lib/discovery/MIGRATION_PLAN.md) |
| Experience | [packages/vex_engines/lib/experience/README.md](../../packages/vex_engines/lib/experience/README.md) | [MIGRATION_PLAN.md](../../packages/vex_engines/lib/experience/MIGRATION_PLAN.md) |
| Claim | [packages/vex_engines/lib/claim/README.md](../../packages/vex_engines/lib/claim/README.md) | [MIGRATION_PLAN.md](../../packages/vex_engines/lib/claim/MIGRATION_PLAN.md) |
| Analytics | [packages/vex_engines/lib/analytics/README.md](../../packages/vex_engines/lib/analytics/README.md) | [MIGRATION_PLAN.md](../../packages/vex_engines/lib/analytics/MIGRATION_PLAN.md) |
