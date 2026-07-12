# Venue Engine

## Overview

Tenant-scoped venue business capability: public profile orchestration, management workflows, opening hours, contact details, gallery/media semantics, profile completion, and venue-specific validation.

## Purpose

Give venues one authoritative place for **profile and management business rules** without owning cross-venue discovery or published drink/deal/event content (Experience Engine).

## Responsibilities

- Opening hours formatting and validation
- Contact and website normalisation
- Image position and branding field parsing
- Profile completion scoring
- Admin CRM venue health, completeness, and quality scoring
- Profile update orchestration (`VenueProfileUpdateService`)
- Venue-specific validation and write **preparation** (adapters persist)

## Version

**Version 1** — launch engine.

## Dependencies

- VexCore: authentication, identity, permissions, `VenueDataService`, storage, events, configuration, observability
- Experience Engine: owns drinks, deals, events content rules (Venue consumes reads only where needed)

## Uses VexCore Layers

| Layer | Usage |
| --- | --- |
| Identity & permissions | Venue staff context, owner checks |
| Vex Data Engine | `VenueDataService` public reads; future management write contracts |
| Storage | Gallery and media upload semantics |
| Observability | Profile update audit |

## Owns

- Venue profile field codec and constants
- Opening hours domain rules
- Image field parser and profile completion calculator
- Admin health scoring (`VenueAdminHealthService`)
- Profile update preparation payloads

## Consumes

- VexCore public venue read snapshots
- Identity context for tenant-scoped operations

## Provides

- `VenueProfileUpdateService` and shared helpers (`VenueContactUtils`, `VenueOpeningHoursFormatter`, etc.)
- Web/mobile facades for profile writes

## Current Status

**~85% complete** (Engine Acceptance Rule partially met)

| Phase | Status |
| --- | --- |
| Structure + migration plan | Complete |
| Shared helpers | Complete |
| Domain rules | Complete |
| Profile update orchestration | Complete |
| Admin CRM health scoring | Complete |
| Web venue media storage via VexCore (`uploadBrandingImage`, gallery delete) | Complete (pilot) |
| Broader management orchestration | Planned |

## Future Features

- Dashboard aggregation workflows
- Broader venue management repository writes through engine contracts
- Presentation view models under `presentation/web/` and `presentation/mobile/`

## Technical Notes

- Public venue **reads** stay in VexCore; engine owns **management** semantics.
- Migrations must not add network calls on hot paths.
- Package: `packages/vex_engines/lib/venue/`

## Known Risks

- Duplicated subscription entitlements still in app monetisation services until Growth Engine migrates.
- Public Firestore venue documents may expose owner metadata — VexCore DTO filtering required on reads.

## Outstanding Work

- Phase 4 orchestration and broader management workflows
- Complete web/mobile delegation for remaining profile management paths
- Presentation layer migration

**Deep dive:** [packages/vex_engines/lib/venue/README.md](../../packages/vex_engines/lib/venue/README.md) · [MIGRATION_PLAN.md](../../packages/vex_engines/lib/venue/MIGRATION_PLAN.md)
