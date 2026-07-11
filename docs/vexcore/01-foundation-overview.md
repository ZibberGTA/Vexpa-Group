# Foundation Overview

## What VexCore Is

VexCore is Vexda's controlled shared infrastructure layer. It defines contracts and shared primitives for authentication, identity, permissions, data access, storage, configuration, events, integrations, observability, and audit.

VexCore is not a UI framework and not a business-engine implementation. It exists so mobile, web, future admin portal, future venue portal, and Vexda Engines can share infrastructure contracts without depending directly on Firebase implementation details.

## Why Vexda Needs It

The current mobile and web apps both contain Firebase Auth, Firestore, Storage, role resolution, permission checks, route guards, and repository logic. Several concepts are duplicated with different names or thresholds. VexCore gives the platform a place to centralise infrastructure contracts before migrating implementations safely.

## Consumers

Mobile, web, admin portal, venue portal, and future engines should consume VexCore contracts. Firebase-specific code will eventually live behind VexCore infrastructure adapters.

```text
Presentation
    ↓
Application or Engine
    ↓
VexCore contracts
    ↓
VexCore infrastructure adapters
    ↓
Firebase and external services
```

## Commands, Queries, and Events

Not every operation is event-based. Commands and queries that require an immediate answer should call VexCore services or repositories directly. Completed business actions may publish domain events so other systems can react.

The event bus must not replace normal request-response calls.

## Foundation 1.0 Includes

- Parent-level package structure under `packages/`.
- Pure Dart `vex_core` package with minimal compiling contracts, enums, value objects, result types, and barrel exports.
- Placeholder `vex_engines` package with documented engine boundaries.
- Current code audit for mobile and web.
- Firebase access, identity, permission, duplication, migration, and risk documentation.

## Foundation 1.0 Excludes

- Feature migration.
- Firebase adapters.
- Firebase Rules changes.
- New production Firebase integrations.
- Runtime imports from app code into VexCore.
- Final identity model decisions.

## Foundation 1.0 — Locked (2026-07-11)

Version 1 contracts are complete and locked. See [11-foundation-lock.md](./11-foundation-lock.md) for scope, rules, deprecated modules, and the post-lock adoption backlog.

**Adoption** (AuthGate, route guards, repository adapters) continues independently of the lock.
- Final engine APIs.
- Deployment.
