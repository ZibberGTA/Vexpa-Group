# Trail Engine

## Overview

Trail composition, trail publishing, route metadata, and trail discovery business workflows. Trails appear in the **Version 1 product** (search filters, trail details pages, `trails` collection) but the Trail Engine package is currently a **placeholder**.

## Purpose

Eventually own trail-specific rules separately from generic Discovery search so trail stops, ordering, walking time, and curation logic have one home.

## Responsibilities

(planned)

- Trail composition and stop ordering rules
- Trail publishing lifecycle
- Route metadata and estimated duration calculations
- Trail discovery eligibility and matching
- Admin curation workflows (coordination with admin portal)

## Version

**Product: Version 1** · **Engine migration: Version 1.5** (planned).

## Dependencies

- VexCore: data access, identity, permissions, events, integrations, observability
- Discovery Engine: trail matches in unified search until Trail Engine owns composition rules
- Venue Engine / Experience: stop venues reference venue and content snapshots

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Vex Data Engine | Trail read/write contracts |
| Permissions | Curation and publish rights |

## Owns

(planned) Trail domain entities, stop ordering invariants, publish rules.

## Consumes

(planned) Venue snapshots, deal/drink availability along route from adapters.

## Provides

(planned) Trail composition services; web/mobile facades for trail details and admin curation.

## Current Status

**Placeholder only** — README boundary exists at `packages/vex_engines/lib/trail/`. Trail behaviour partially implemented in app search and web trail pages.

## Future Features

- Full engine migration from app-inline trail logic
- Integration with Discovery unified search as consumer
- Generated trails (admin) per [WEB_ARCHITECTURE.md](../../apps/nightlife_web/docs/WEB_ARCHITECTURE.md)

## Technical Notes

- Do not import Flutter map widgets or Firebase SDKs in engine layers when implemented.
- Until migration, Discovery Engine handles trail **matching** in unified search; Trail Engine will own **composition**.

## Known Risks

- Split ownership between Discovery search and future Trail Engine during migration window.
- Trail data model (`stops[]`) must remain stable for mobile/web parity.

## Outstanding Work

- Audit app trail logic for migration inventory
- Define trail repository contracts
- Implement domain and application layers
- Wire web Trail Details and admin Trails pages through engine

**Deep dive:** [packages/vex_engines/lib/trail/README.md](../../packages/vex_engines/lib/trail/README.md)
