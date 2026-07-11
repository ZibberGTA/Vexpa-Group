# ADR-0002: Version 1 Scope

## Status

Accepted — 2026-07-11

## Context

Vexda's product vision spans discovery, venue management, growth, commerce, and distribution. Building everything at launch would delay validation, overload a small team, and entangle immature domains.

The codebase already contains precursor features (trails in search, boosts/subscriptions in mobile, artist dashboard) that must be distinguished from **Version 1 launch commitment**.

## Decision

**Version 1** delivers the nightlife discovery and venue growth **launch platform** with these **launch engines**:

| Engine | In Version 1 |
| --- | --- |
| Venue | Yes |
| Discovery | Yes |
| Experience | Yes (drinks, deals, events) |
| Claim | Yes |
| Analytics | Yes |
| Trail | Product yes; engine migration deferred to 1.5 |

**Explicitly NOT Version 1:**

- Ticketing
- Bookings
- Membership
- Ordering
- POS
- Distribution platform

Future engines are **documented and folder-scoped** where applicable but not implemented for launch.

Experience Engine **replaces** separate Drink, Deal, and Event engines for Version 1.

## Consequences

### Positive

- Clear prioritisation for engineering and product.
- Prevents scope creep into commerce before discovery/venue loops work.
- Engine folders for future work without implying launch readiness.

### Negative

- Some mobile UI hints (messages, bookings) remain hidden or stubbed until later versions.
- Trail logic temporarily split between Discovery search and unmigrated trail-specific rules.

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| Ship booking/ticketing in V1 | No engine home; increases Firebase complexity before core migration done |
| Defer all engines to V2 | Perpetuates mobile/web duplication at launch |
| Single "Core" engine for V1 | Violates single-responsibility; blocks team scaling |

## Future review

Each new engine entering active development requires an ADR amendment or new ADR confirming version assignment.

**References:** [master-blueprint.md §6](../master-blueprint.md), [engines/README.md](../engines/README.md)
