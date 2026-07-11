# ADR-0009: Documentation Policy

## Status

Accepted — 2026-07-11

## Context

Vexda's architecture exceeds what one conversation or one engineer can hold in memory. Undocumented decisions revert to tribal knowledge; duplicated logic returns; new hires cannot safely contribute.

Foundation 1.0 created `docs/vexcore/` and per-engine READMEs but lacked a single entry point and decision log. Multiple documents referenced `docs/master-blueprint.md` before it existed.

## Decision

1. **Documentation is part of the product** — not an afterthought to implementation.
2. **Single entry point:** [docs/master-blueprint.md](../master-blueprint.md) for company, product, and platform organisation.
3. **Technical depth** stays in VexCore docs, engine READMEs, migration plans, and web architecture — **cross-referenced**, not duplicated in the blueprint.
4. **Architecture Decision Records** live in [docs/decisions/](../decisions/README.md) with sequential numbering.
5. **Every major architectural or product decision** must update **either** the Master Blueprint **or** an ADR **before** implementation merges.
6. **Engine catalogue** at [docs/engines/](../engines/README.md) maintains one summary page per engine with uniform structure.
7. Major scope changes (new engine, version reassignment, database migration) require ADR + blueprint §13 update.

"Major" includes: new engine boundary, VexCore contract breaking change, version scope change, new platform surface, database strategy change, security model change.

## Consequences

### Positive

- Onboarding path for future engineers (50+ team target).
- Decisions searchable and auditable.
- Product and engineering share vocabulary.

### Negative

- Documentation maintenance overhead.
- Risk of stale docs if policy not enforced in review.

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| Wiki-only (Notion/etc.) | Disconnected from repo; drifts from code |
| Code comments only | Not discoverable for product/leadership |
| No formal policy | Already caused "master-blueprint missing" references |

## Future review

Add CI check or PR template reminder when team size exceeds ~8 engineers.

**References:** [docs/README.md](../README.md), [master-blueprint.md §13 #010](../master-blueprint.md)
