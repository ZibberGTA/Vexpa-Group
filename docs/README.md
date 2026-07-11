# Vexda Documentation

Permanent documentation for the Vexda platform. This tree is the **single source of truth** for company direction, product philosophy, platform architecture, engine boundaries, and locked decisions.

## Start here

| Document | Audience | Purpose |
| --- | --- | --- |
| [Master Blueprint](./master-blueprint.md) | Leadership, product, engineering | CEO handbook — organises all documentation without duplicating technical detail |
| [VexCore Foundation](./vexcore/README.md) | Engineers | Infrastructure contracts, dependency rules, migration roadmap |
| [Engine Catalogue](./engines/README.md) | Engineers, product | One page per business engine |
| [Architecture Decisions](./decisions/README.md) | Everyone | Locked ADRs — read before changing architecture |

## Product and web

| Document | Location |
| --- | --- |
| Product principles | [apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md](../apps/nightlife_web/docs/VEXDA_PRODUCT_PRINCIPLES.md) |
| Web architecture and sitemap | [apps/nightlife_web/docs/WEB_ARCHITECTURE.md](../apps/nightlife_web/docs/WEB_ARCHITECTURE.md) |
| Monorepo runbook | [README.md](../README.md) |

## Engine technical docs (in code)

Each implemented engine maintains a README and migration plan beside its source:

```text
packages/vex_engines/lib/<engine>/
  README.md
  MIGRATION_PLAN.md
```

## Documentation policy

Every major architectural or product decision must update **either**:

1. [master-blueprint.md](./master-blueprint.md) — for company, product, or cross-cutting platform decisions, **or**
2. An [ADR](./decisions/README.md) — for technical architecture decisions

Implementation should not precede documentation for decisions that affect engine boundaries, VexCore contracts, version scope, or data ownership.

See [ADR-0009: Documentation Policy](./decisions/0009-documentation-policy.md).

## Revision

| Version | Date | Summary |
| --- | --- | --- |
| 1.0 | 2026-07-11 | Initial permanent documentation foundation |
