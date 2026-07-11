# Distribution Engine

## Overview

Future **Distribution platform** for partner/supplier distribution — a separate product from consumer discovery. Uses VexCore; not embedded in the consumer mobile app or marketing website.

## Purpose

Enable B2B distribution workflows (partner catalogues, fulfilment handoffs, partner permissions) without contaminating Version 1 discovery engines.

## Responsibilities

(planned)

- Partner identity and tenancy boundaries
- Distribution catalogue and availability rules
- Partner order/fulfilment orchestration (exact product TBD — requires future ADRs)
- Revenue share calculation inputs

## Version

**Version 4+** — **NOT Version 1**.

## Dependencies

- VexCore: full infrastructure stack — same as other platforms ([ADR-0008](../decisions/0008-distribution-platform.md))
- Venue/Experience data via **public contracts** only — no private engine persistence reads

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Identity & permissions | Partner vs venue vs Vexda staff |
| Vex Data Engine | Distribution-specific repositories |
| Integrations | Partner APIs, ERP hooks |
| Audit | Partner transaction audit |

## Owns

(planned) Distribution domain rules on the Distribution **platform**.

## Consumes

(planned) Venue and product snapshots via approved VexCore read APIs.

## Provides

(planned) Distribution platform APIs and partner portal (separate deploy from consumer web).

## Current Status

**Not implemented** — no package folder. Documented as future-only in Experience Engine boundaries and Version 1 scope exclusion.

## Future Features

- Standalone Distribution platform UI
- Partner onboarding and catalog management
- Revenue share reporting

## Technical Notes

- Distribution becomes **its own platform** consuming VexCore — not a `/admin` or `/portal` subsection.
- Consumer apps may deep-link/hand off; they do not host Distribution workflows.

## Known Risks

- Premature logic in Discovery/Experience engines — guard with ADR-0008 reviews.
- Tenancy and data ownership complexity — requires dedicated ADR before build.

## Outstanding Work

- Distribution product definition ADR (tenancy, revenue model)
- Platform architecture (deploy, domain, auth federation)
- Engine package creation under `packages/vex_engines/lib/distribution/`

**References:** [ADR-0008 Distribution Platform Strategy](../decisions/0008-distribution-platform.md), [master-blueprint.md §7](../master-blueprint.md)
