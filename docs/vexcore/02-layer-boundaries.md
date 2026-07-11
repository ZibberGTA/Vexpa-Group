# Layer Boundaries

## Authentication

| Item | Detail |
| --- | --- |
| Purpose | Session lifecycle and authenticated user access. |
| Responsibilities | Sign in, sign out, current user, auth state stream, auth exceptions. |
| Allowed dependencies | Shared primitives and future auth adapter interfaces. |
| Forbidden responsibilities | Role resolution, widget redirects, Firebase Auth imports in pure contracts. |
| Example consumers | Login flows, route guards, identity resolver. |

## Identity

| Item | Detail |
| --- | --- |
| Purpose | Resolve who an authenticated actor is inside Vexda. |
| Responsibilities | UID, email, account status, roles, venue assignments, identity source metadata once decided. |
| Allowed dependencies | Authentication contracts, shared primitives, data contracts. |
| Forbidden responsibilities | UI state, direct permission decisions, raw Firestore path scattering. |
| Example consumers | Permission evaluator, admin guard, venue dashboard guard. |

## Permissions

| Item | Detail |
| --- | --- |
| Purpose | Decide whether an identity may perform an action in context. |
| Responsibilities | Permission enum, context-aware allow/deny decisions, reason strings. |
| Allowed dependencies | Identity contracts and shared primitives. |
| Forbidden responsibilities | Fetching Firebase documents directly from widgets, owning route rendering. |
| Example consumers | Admin dashboard, venue portal, engines before commands. |

## Vex Data Engine

| Item | Detail |
| --- | --- |
| Purpose | Common contracts for repositories, paging, data results, and future persistence adapters. |
| Responsibilities | Repository interfaces, pagination, typed result wrappers, adapter boundary. |
| Allowed dependencies | Shared primitives, identity/permission context where required. |
| Forbidden responsibilities | Domain workflows, UI mapping, hard-coded Firebase collections in domain folders. |
| Example consumers | Admin repositories, public discovery repositories, venue management repositories. |

## Storage

| Item | Detail |
| --- | --- |
| Purpose | Abstract upload, download URL, metadata, and deletion operations. |
| Responsibilities | Storage service contract, document metadata/reference types, document access evaluator, storage result value object. |
| Version 1 implementations | `VexDocumentStorageService` contract, `DocumentAccessEvaluator`, `VexStorageService` — Firebase adapters remain in apps. |
| Allowed dependencies | Shared primitives and permission context. |
| Forbidden responsibilities | UI image picking, direct Firebase Storage imports in engines. |
| Example consumers | Venue media uploads, gallery management, marker image loading. |

## Event Bus

| Item | Detail |
| --- | --- |
| Purpose | Publish completed business actions for downstream reaction. |
| Responsibilities | Event base type, publish, subscribe, subscription cancellation. |
| Version 1 implementations | `InProcessVexEventBus`, typed platform events (`VenueProfileUpdatedEvent`, etc.). |
| Allowed dependencies | Shared primitives and clock. |
| Forbidden responsibilities | Replacing direct commands/queries, UI state propagation. |
| Example consumers | Claim approved event, venue media uploaded event, subscription changed event. |

## Integrations and API

| Item | Detail |
| --- | --- |
| Purpose | Wrap external APIs and callable functions behind contracts. |
| Responsibilities | Integration clients, integration result/error model. |
| Allowed dependencies | Shared primitives, configuration, observability. |
| Forbidden responsibilities | Embedding provider SDKs in engines or widgets. |
| Example consumers | Cloud Functions claim submission, Stripe checkout, maps/directions. |

## Configuration and Feature Flags

| Item | Detail |
| --- | --- |
| Purpose | Centralise environment and feature flag reads. |
| Responsibilities | Environment enum, flag lookup, config values. |
| Allowed dependencies | Shared primitives. |
| Forbidden responsibilities | Route rendering, widget-specific constants, Firebase Remote Config implementation in contracts. |
| Example consumers | Private development gate, environment-specific adapters. |

## Observability and Audit

| Item | Detail |
| --- | --- |
| Purpose | Logging, error reporting, and audit event contracts. |
| Responsibilities | Logger, error reporter, audit recording interface. |
| Allowed dependencies | Shared primitives and event contracts. |
| Forbidden responsibilities | Business authorization, leaking confidential tenant data. |
| Example consumers | Admin operations, media uploads, claim review, role resolver diagnostics. |

## Shared Primitives

| Item | Detail |
| --- | --- |
| Purpose | Cross-layer primitives that are not feature-specific. |
| Responsibilities | Base exceptions, result types, clock, identifiers. |
| Allowed dependencies | Dart SDK only. |
| Forbidden responsibilities | Firebase models, UI models, engine-specific workflows. |
| Example consumers | All VexCore layers and engines. |
