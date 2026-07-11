# Membership Engine

## Overview

Future engine for **customer membership, loyalty, and venue membership programmes**. Not part of Version 1.

## Purpose

Own membership tier rules, benefits, and eligibility separately from venue **subscription** entitlements (Growth Engine).

## Responsibilities

(planned)

- Consumer membership enrolment rules
- Benefit and reward eligibility
- Venue-specific loyalty programme semantics
- Membership status lifecycle

## Version

**Version 3** — **NOT Version 1**.

## Dependencies

- VexCore: identity, permissions, data access, events, integrations
- Growth Engine: venue subscription vs consumer membership distinction must remain clear

## Uses VexCore Layers

| Layer | Usage (planned) |
| --- | --- |
| Identity | Member profile linkage |
| Permissions | Benefit redemption authorization |
| Vex Data Engine | Membership read/write contracts |

## Owns

(planned) Membership domain rules and benefit calculations.

## Consumes

(planned) Venue and user identity; transaction events from future commerce engines when applicable.

## Provides

(planned) Membership eligibility APIs for consumer app and venue portal.

## Current Status

**Not implemented** — no package folder. No Version 1 product commitment.

## Future Features

- Venue loyalty programmes
- Cross-venue membership (if product approves — requires ADR)

## Technical Notes

- Distinguish **Growth** (venue pays Vexda) from **Membership** (consumer loyalty to venues).

## Known Risks

- Scope overlap with Growth/subscription if boundaries undefined.

## Outstanding Work

- Product definition and ADR before engine creation
- Package scaffold when Version 3 starts

**References:** [ADR-0002](../decisions/0002-version-1-scope.md), [master-blueprint.md §6](../master-blueprint.md)
