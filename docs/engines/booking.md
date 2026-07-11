# Booking Engine

## Overview

Future engine for **table bookings, reservations, and appointment-style venue bookings**. Explicitly excluded from Version 1.

## Purpose

Own booking availability, reservation lifecycle, and confirmation rules when product expands into reservations.

## Responsibilities

(planned)

- Booking slot and availability models
- Reservation create/modify/cancel rules
- Conflict detection and capacity limits
- Confirmation and reminder preparation

## Version

**Version 4** — **NOT Version 1**.

## Dependencies

- VexCore: identity, permissions, data access, events, integrations, observability
- Venue Engine: venue hours and capacity context
- Notifications via integrations (not in engine UI layer)

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Vex Data Engine | Booking persistence contracts |
| Events | Booking confirmed/cancelled |
| Integrations | Calendar/notification providers |

## Owns

(planned) Booking business rules and state machine.

## Consumes

(planned) Venue opening hours, capacity, owner policies from adapters.

## Provides

(planned) Booking APIs for consumer app, venue portal, and optional POS integration.

## Current Status

**Not implemented.** Mobile playthrough notes removed consumer "My Bookings" from account — precursor UI only. Artist dashboard references booking tools separately.

## Future Features

- Table reservations
- Event-linked bookings (coordination with Ticketing Engine)

## Technical Notes

- Transactional integrity may motivate PostgreSQL participation ([ADR-0006](../decisions/0006-database-strategy.md)).

## Known Risks

- Double-booking if rules split between app and engine during migration.

## Outstanding Work

- Product scope ADR
- Engine package creation under `packages/vex_engines/lib/booking/`

**References:** [ADR-0002](../decisions/0002-version-1-scope.md)
