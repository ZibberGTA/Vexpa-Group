# Claim Engine

## Overview

Version 1 launch engine for **venue ownership claims**: submission validation, evidence rules, status transitions, admin review decisions, confidence scoring, search orchestration, and audit preparation.

## Purpose

Own the claim **workflow business rules** separately from VexCore auth/permissions and admin UI shells.

## Responsibilities

- Claim submission validation and payload preparation
- Claim status model and allowed transitions
- Evidence validation, interpretation, completeness, and confidence scoring
- Admin review decision validation, metrics, and summaries
- Ownership transfer and audit event preparation
- Claim search interpretation, candidate matching, dedupe, ranking, and ordering
- Deterministic claim list ordering and malformed record handling

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
| Storage | Evidence upload contracts (`VexDocumentStorageService`) |
| Events | Claim approved/completed actions |
| Integrations | Callable submission path (adapter) |

## Owns

- Claim domain models, evidence rules, scoring algorithms
- Submission, review, search, summary, and evidence interpretation services

## Consumes

- Identity and permission context from VexCore
- Venue search snapshots for claim matching (via adapters)

## Provides

- `ClaimSubmissionService`, `ClaimReviewService`, `ClaimSearchService`, `ClaimSummaryService`, `ClaimEvidenceInterpretation`
- Web: `VenueClaimRepository` wired for search/submission/review/scoring
- Callable names and payloads unchanged at Firebase boundary

## Current Status

**~92% complete**

| Phase | Status |
| --- | --- |
| Shared rules | Complete |
| Submission + review services | Complete |
| Web runtime slice | Complete |
| Search orchestration + summaries | Complete |
| Web evidence document policy + path conventions | Complete |
| Web evidence upload via VexCore document adapter | Complete |
| Firebase Storage rules for private claim evidence | **Committed — not emulator-validated / not deployed** |
| Mobile claim flow | Planned |
| Engine write repository interfaces | Planned |

## Future Features

- Mobile claim UI consuming same engine
- Engine-owned repository interfaces in `data/`
- Presentation layer for claim pages

## Technical Notes

- Engine work is in-memory validation and ordering only — no added Firestore/listener/callable cost.
- Firebase, Firestore, Storage, and Cloud Functions remain adapters in `apps/nightlife_web`.
- VexCore Foundation 1.0 contracts remain locked; no breaking VexCore changes in this batch.
- Package: `packages/vex_engines/lib/claim/`

## Known Risks

- Mobile has no claim flow yet — web-only increases onboarding friction for some owners.
- Storage rules require Java for emulator validation before deploy.
- Client/server confidence scoring may diverge from Cloud Functions until server migration.

## Outstanding Work

- Storage rules emulator validation and deploy (when Java available)
- Mobile adoption
- Claim page draft form extraction (optional)
- Write repository contracts

**Deep dive:** [packages/vex_engines/lib/claim/README.md](../../packages/vex_engines/lib/claim/README.md) · [MIGRATION_PLAN.md](../../packages/vex_engines/lib/claim/MIGRATION_PLAN.md)
