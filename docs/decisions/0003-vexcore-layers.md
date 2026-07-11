# ADR-0003: VexCore Layers

## Status

Accepted — 2026-07-11  
**Foundation 1.0 locked** — 2026-07-11 ([11-foundation-lock.md](../vexcore/11-foundation-lock.md))

## Context

Mobile and web each implemented authentication, role resolution, permission checks, and Firestore access independently. Without a shared infrastructure layer, every migration and every new surface repeats the same work and risks inconsistent security behaviour.

## Decision

Establish **VexCore** (`packages/vex_core`) as the **only** shared infrastructure contract layer with these named layers:

| Layer | Responsibility |
| --- | --- |
| Authentication | Session lifecycle |
| Identity | Role and venue assignment resolution |
| Permissions | Context-aware authorization |
| Vex Data Engine | Repository contracts, paging, results |
| Storage | File upload/download abstraction |
| Event Bus | Publish/subscribe for **completed** actions only |
| Integrations & API | External services and Cloud Functions |
| Configuration | Environment and feature flags |
| Observability & Audit | Logging, errors, audit trail |
| Shared primitives | Results, exceptions, clock, IDs |

Rules:

1. Pure VexCore **contracts** contain no Firebase or Flutter imports.
2. **Nothing bypasses VexCore** for shared infrastructure — new surfaces use contracts.
3. Commands and queries use direct service/repository calls; the event bus does not replace request/response.
4. Engines depend on VexCore; VexCore does not depend on engines.

## Consequences

### Positive

- One definition of identity and permissions across admin, portal, and mobile.
- Adapter swap (Firebase → PostgreSQL) localized to infrastructure.
- Testable contracts without Firebase emulators for pure logic.

### Negative

- Upfront contract design before all adapters exist.
- Temporary dual paths during migration (legacy services + VexCore pilots).

## Alternatives considered

| Alternative | Why rejected |
| --- | --- |
| Shared utility classes in apps | No enforcement; drift continues |
| Firebase as the "core" | Locks business logic to vendor SDK |
| GraphQL/BFF only | Does not solve identity/permission duplication inside apps |

## Future review

When PostgreSQL migration begins, add ADR for adapter package structure and transaction boundaries.

**References:** [01-foundation-overview.md](../vexcore/01-foundation-overview.md), [02-layer-boundaries.md](../vexcore/02-layer-boundaries.md), [03-dependency-rules.md](../vexcore/03-dependency-rules.md), [11-foundation-lock.md](../vexcore/11-foundation-lock.md)
