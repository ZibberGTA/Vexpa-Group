# VexCore Foundation 1.0 — Locked

**Status:** Locked — 2026-07-11  
**Branch context:** `feature/vexcore-identity-foundation`

## Lock scope

The following **public contract surface** in `packages/vex_core` is frozen for Version 1:

- Exports from `packages/vex_core/lib/vex_core.dart`
- Authentication contracts
- Identity contracts and `RoleResolver`
- Permission contracts, `RouteAccess`, and `AdminPermissionMatrix`
- Entitlement contracts
- `DataResult` / failure primitives
- Event bus interface and in-process implementation
- Configuration contracts and in-memory defaults
- Logging and error-reporting contracts
- Storage and document contracts
- Provider-independent repository and data-service contracts

## Lock rules

| Rule | Detail |
| --- | --- |
| Backward-compatible additions | Allowed (new types, optional fields, new methods). |
| Breaking changes | Require an ADR and explicit founder approval. |
| VexCore dependencies | Must not import Firebase, Flutter, or `vex_engines`. |
| Business rules | No new venue, discovery, experience, claim, or analytics rules in VexCore. |
| Call direction | Apps → Engines → VexCore → adapters → infrastructure. |
| Composition roots | App roots (`WebVexCore`, `MobileVexCore`) may wire engines **and** VexCore; the **package** must not call engines. |
| Adoption | Ongoing after lock — see adoption backlog below. |

## Deprecated modules (frozen, not removed)

| Module | Canonical owner |
| --- | --- |
| `venue_deal_visibility.dart` | Experience Engine — `ExperienceDealVisibility` |
| `venue_event_visibility.dart` | Experience Engine — `ExperienceEventVisibility` |
| Drink filtering in `VenueDrinkDataService` | Experience Engine — `ExperienceDrinkVisibility` |

Do not add new business rules to deprecated modules.

## Distinction

| Track | Meaning |
| --- | --- |
| **Foundation completion** | Contracts and pure logic in `packages/vex_core` |
| **Adoption progress** | Apps routing through composition roots and engines |
| **Adapter migrations** | Firebase implementations behind VexCore interfaces |
| **Post-launch** | Enforcement automation, external brokers, PostgreSQL |

## Adoption backlog (post-lock)

- Firebase document-storage adapters (`VexDocumentStorageService`)
- Venue media storage adapter (`VexStorageService`)
- Claim Engine evidence upload adapter
- Cloud Functions integration adapters
- Remaining direct Firestore paths (admin, claims, map, search, mobile legacy screens)
- Broader entitlement adoption in billing/subscription UI
- Duplicate mobile admin permission service cleanup
- Phase 9 automated architecture enforcement (import/Firebase boundary checks)
- Web UI reduction of parallel `UserRoleService` subscriptions where `WebVexCore.identity` suffices

## Rollback

Adapters and app facades can revert to legacy services without changing locked VexCore contracts. Deprecated visibility helpers remain for backward compatibility until all consumers migrate to Experience Engine boundaries.
