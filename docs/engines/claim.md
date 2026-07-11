# Claim Engine

## Overview

Version 1 launch engine for **venue ownership claims**: submission validation, evidence rules, status transitions, admin review decisions, confidence scoring, and audit preparation.

## Purpose

Own the claim **workflow business rules** separately from VexCore auth/permissions and admin UI shells.

## Responsibilities

- Claim submission validation and payload preparation
- Claim status model and allowed transitions
- Evidence validation and confidence scoring
- Admin review decision validation
- Ownership transfer and audit event preparation
- Claim search eligibility and matching helpers

## Version

**Version 1** — launch engine.

## Dependencies

- VexCore: authentication, identity, permissions, storage, events, `DataResult`
- Venue Engine: does not edit venue profile — claim approval triggers separate workflows

## Uses VexCore Layers

| Layer | Usage |
| --- | --- |
| Authentication & identity | Claimant context |
| Permissions | Admin review authorization |
| Storage | Evidence upload contracts |
| Events | Claim approved/completed actions |
| Integrations | Callable submission path (adapter) |

## Owns

- Claim domain models, evidence rules, scoring algorithms
- Submission and review application services

## Consumes

- Identity and permission context from VexCore
- Venue search snapshots for claim matching (via adapters)

## Provides

- `ClaimSubmissionService`, `ClaimReviewService`, `ClaimEvidenceValidator`, confidence scoring
- Web: `VenueClaimRepository` wired for submission/review/scoring
- Callable `submitVenueClaim` path unchanged at Firebase boundary

## Current Status

**~70% complete**

| Phase | Status |
| --- | --- |
| Shared rules | Complete |
| Submission + review services | Complete |
| Web runtime slice | Complete |
| Mobile claim flow | Planned |
| Admin presentation view models | Planned |

## Future Features

- Mobile claim UI consuming same engine
- Engine-owned repository interfaces in `data/`
- Presentation layer for claim pages

## Technical Notes

- Engine work is in-memory validation only — no added Firestore/listener cost.
- Package: `packages/vex_engines/lib/claim/`

## Known Risks

- Mobile has no claim flow yet — web-only increases onboarding friction for some owners.
- Evidence storage paths must remain venue-scoped and permission-checked in adapters.

## Outstanding Work

- Mobile adoption
- Admin UI view model extraction
- Write repository contracts

**Deep dive:** [packages/vex_engines/lib/claim/README.md](../../packages/vex_engines/lib/claim/README.md) · [MIGRATION_PLAN.md](../../packages/vex_engines/lib/claim/MIGRATION_PLAN.md)
