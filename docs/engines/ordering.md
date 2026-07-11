# Ordering Engine

## Overview

Future engine for **in-venue and pre-order purchasing** of drinks and food through Vexda. Explicitly excluded from Version 1.

## Purpose

Own order basket, fulfilment, and order state rules when product moves from discovery into commerce.

## Responsibilities

(planned)

- Order creation and modification rules
- Line item validation against Experience/menu data
- Order status lifecycle (placed, preparing, ready, completed)
- Handoff to POS or venue fulfilment workflows

## Version

**Version 4** — **NOT Version 1**.

## Dependencies

- VexCore: identity, permissions, integrations, data access, events
- Experience Engine: product/menu item snapshots
- POS Engine: fulfilment integration — via public interfaces

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Integrations | Payment and POS handoff |
| Events | Order placed/completed |
| Vex Data Engine | Order persistence contracts |

## Owns

(planned) Order domain rules and state transitions.

## Consumes

(planned) Menu/drink/deal availability from adapters; payment status from integrations.

## Provides

(planned) Ordering APIs for consumer app and venue portal order management.

## Current Status

**Not implemented** — no package folder.

## Future Features

- Mobile order-ahead
- Venue order queue management

## Technical Notes

- Real-time order status may use Firebase or future message bus — adapters only.

## Known Risks

- Overlap with POS Engine if boundaries not defined before build.

## Outstanding Work

- Product ADR for ordering vs POS split
- Package scaffold under `packages/vex_engines/lib/ordering/`

**References:** [ADR-0002](../decisions/0002-version-1-scope.md)
