# POS Engine

## Overview

Future engine for **point-of-sale integration, tab management, and redemption tracking** connecting venue operations to Vexda discovery and ordering.

## Purpose

Own POS-side business rules (redemption, tab sync semantics) without embedding vendor SDKs in consumer apps.

## Responsibilities

(planned)

- Deal/drink redemption validation against Experience rules
- Tab or check synchronization semantics (vendor-specific in adapters)
- Revenue attribution inputs for Analytics
- Owner revenue dashboard signals (mobile notes reference future POS/deal redemption tracking)

## Version

**Version 4** — **NOT Version 1**.

## Dependencies

- VexCore: integrations, identity, permissions, events, observability
- Experience Engine: offer validity rules
- Ordering Engine: shared order lifecycle boundaries
- Analytics Engine: revenue signal consumption via aggregates

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Integrations | POS vendor APIs |
| Events | Redemption completed |
| Audit | Financial audit trail |

## Owns

(planned) Redemption and POS orchestration rules — not vendor wire protocols.

## Consumes

(planned) Active deals/drinks, venue context, POS adapter responses.

## Provides

(planned) Redemption validation services; portal POS integration settings.

## Current Status

**Not implemented.** Owner analytics includes **estimated** visits/revenue until real POS/deal redemption connected ([BUILD_NOTES_NEXT_LEVEL.md](../../apps/nightlife_app/lib/BUILD_NOTES_NEXT_LEVEL.md)).

## Future Features

- POS partner integrations
- Real redemption tracking for ROI analytics

## Technical Notes

- Vendor SDKs strictly in VexCore integration adapters.
- Experience Engine README lists POS as out of scope for Experience.

## Known Risks

- Estimates vs actuals gap until POS Engine ships — document in Analytics outputs.

## Outstanding Work

- POS partner strategy ADR
- Package scaffold under `packages/vex_engines/lib/pos/`

**References:** [ADR-0002](../decisions/0002-version-1-scope.md), [master-blueprint.md §10](../master-blueprint.md)
