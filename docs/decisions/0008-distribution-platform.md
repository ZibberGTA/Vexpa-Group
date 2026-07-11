# ADR-0008: Distribution Platform Strategy

## Status

Accepted — 2026-07-11

## Context

"D distribution" in the Vexda roadmap refers to a future capability for partner/supplier distribution — distinct from consumer venue discovery. It must not be bolted into the consumer mobile app or marketing website as an afterthought.

Experience Engine README explicitly excludes distribution from its scope. Version 1 excludes Distribution entirely.

## Decision

1. **Distribution is NOT Version 1** ([ADR-0002](./0002-version-1-scope.md)).
2. **Distribution will eventually become its own platform** — a separate product surface with its own presentation layer.
3. Distribution **consumes VexCore** for authentication, identity, permissions, data contracts, integrations, and observability — same as other surfaces.
4. Distribution business rules will live in a **Distribution Engine** (or engine group) when implemented — not in Discovery or Experience engines.
5. Consumer apps may **link** or **hand off** to Distribution where product requires; they do not embed Distribution workflows at launch.

## Consequences

### Positive

- Clear separation of consumer vs B2B partner concerns.
- Distribution team can scale independently later.
- VexCore reuse avoids second identity system.

### Negative

- Requires future investment in separate UX and deploy pipeline.
- Integration points with Venue/Experience data must be designed deliberately.

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| Distribution tab in consumer app | Blurs product; wrong user mental model |
| Distribution as admin-only feature | Partners are not Vexda staff |
| No architectural pre-planning | Risk of logic leaking into Version 1 engines |

## Future review

Required before Distribution Version 4 kickoff: tenancy model, revenue share data ownership, and API public vs internal boundary ADR.

**References:** [master-blueprint.md §7](../master-blueprint.md), [engines/distribution.md](../engines/distribution.md)
