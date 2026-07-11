# ADR-0006: Database Strategy

## Status

Accepted — 2026-07-11

## Context

Vexda launches on Firebase Firestore. Document-oriented storage suits rapid iteration but has limits for complex analytics, relational integrity, and cost at scale. The team needs optionality without a premature rewrite.

VexCore was created specifically to decouple business logic from persistence.

## Decision

1. **Launch database:** Firebase Firestore (with Auth, Storage, Functions as related services).
2. **Future option:** Migration to **PostgreSQL** (or another relational database) if scale, reporting, or transactional workloads require it. Timing is **not** committed.
3. **Business logic must never depend directly on Firebase** — only VexCore adapters and app repositories may use Firebase SDKs.
4. **Repository contracts** in VexCore and engine `data/` layers expose engine-neutral DTOs; collection paths exist only in adapters.
5. **Migration approach:** Replace adapter implementations behind stable contracts; engines unchanged.

## Consequences

### Positive

- Launch velocity preserved.
- Long-term escape hatch without fork-lifting engines.
- Forces clean boundaries today.

### Negative

- Dual-model maintenance during any future migration period.
- Some Firestore-specific patterns (array-contains search) may need redesign for SQL.
- Migration project will be non-trivial when triggered.

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| Firestore forever | May not suit Version 4 commerce or distribution reporting |
| Immediate PostgreSQL | Delays Version 1; duplicates working auth/storage |
| Per-engine databases at launch | Operational complexity exceeds team size |

## Future review

Mandatory review before: (a) first PostgreSQL spike, (b) Distribution platform launch, (c) POS/ordering transactional workloads.

**References:** [master-blueprint.md §8](../master-blueprint.md), [03-dependency-rules.md](../vexcore/03-dependency-rules.md)
