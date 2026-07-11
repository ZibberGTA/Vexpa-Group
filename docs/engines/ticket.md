# Ticketing Engine

## Overview

Future engine for **event ticketing, inventory, and admission validation**. Explicitly excluded from Version 1.

## Purpose

Own ticket product definitions, sale rules, inventory, and check-in semantics separately from Experience Engine event **content**.

## Responsibilities

(planned)

- Ticket types and pricing rules
- Inventory and purchase lifecycle
- Refund/cancellation policy enforcement
- Check-in/admission validation rules

## Version

**Version 4** — **NOT Version 1**.

## Dependencies

- VexCore: identity, permissions, integrations (payments), data access, events, audit
- Experience Engine: event metadata for ticket attachment — via public interfaces
- Growth/Ordering engines may intersect at payment boundaries — requires ADRs

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Integrations | Payment providers |
| Audit | Financial and admission audit trail |
| Vex Data Engine | Ticket inventory contracts |

## Owns

(planned) Ticketing domain and commerce rules.

## Consumes

(planned) Event snapshots, venue identity, payment status from adapters.

## Provides

(planned) Ticketing APIs for consumer purchase flows and venue portal management.

## Current Status

**Not implemented** — no package folder.

## Future Features

- Paid event tickets
- QR/admission validation
- Revenue reporting with Analytics Engine

## Technical Notes

- Strong transactional and fraud requirements — likely drives database strategy review.

## Known Risks

- PCI and payment scope — keep card data in integration adapters only.

## Outstanding Work

- Commerce ADR bundle (Ticketing + Ordering + POS)
- Engine scaffold when Version 4 begins

**References:** [ADR-0002](../decisions/0002-version-1-scope.md)
