# VexCore Trail Layer

Firebase-independent infrastructure contracts for Trail documents, user progress, activity logging, and artwork references.

## Purpose

This package layer captures the **current mobile production Firestore schema** and repository operations required by `TrailService`, without embedding Trail business policy. VexTrail will later own lifecycle rules, visibility, progress transitions, and check-in validation. Applications keep UI and navigation.

## Responsibilities

| Layer | Owns |
| --- | --- |
| **VexCore (`lib/trails/`)** | Repository interfaces, snapshot DTOs, path helpers, query/command DTOs, persistence value parsing |
| **VexTrail (future)** | Publishing readiness, visibility, stop ordering rules, progress state machines, geofence validation |
| **Apps** | Flutter widgets, navigation, presentation state, platform adapters |

## Firestore schema (summary)

See [SCHEMA_MAPPING.md](./SCHEMA_MAPPING.md) for field-level documentation.

| Path | Role |
| --- | --- |
| `trails/{trailId}` | Trail document with embedded `stops[]` |
| `users/{uid}/trail_state/active` | `{ activeTrailId, updatedAt }` |
| `users/{uid}/trails/{trailId}/progress/current` | Canonical user progress |
| `trail_progress/{uid}` | Legacy progress mirror when `trailId == activeTrail` |
| `trail_activity/{activityId}` | Append-only activity log |

## Snapshot responsibilities

- **`TrailSnapshot`** — complete trail document including alias fields (`name`/`title`, `description`/`subtitle`, availability/start/end pairs).
- **`TrailStopSnapshot`** — embedded stop fields as persisted today (no coordinates or check-in radius on stops).
- **`TrailProgressSnapshot`** — joined/active/completed state, stop states, check-in metadata, lifecycle timestamps.
- **`TrailActivitySnapshot`** — append-only action records.
- **`TrailActiveStateSnapshot`** — user's active trail pointer.

Snapshots use `DateTime`, `String` IDs, and infrastructure enums — never Firestore SDK types.

## Repository boundaries

Repositories describe **infrastructure operations**, not business decisions:

- `TrailRepository` — CRUD/list/watch on `trails`
- `TrailProgressRepository` — progress CRUD, active state, explicit legacy mirror writes
- `TrailActivityRepository` — append/list activity
- `TrailMediaRepository` — URL resolution today; Storage upload reserved for future

Commands such as `PublishTrailCommand` accept prepared writes. VexCore does **not** implement `canPublishTrail()`.

## Legacy compatibility

- Dual flags: `status` + `published`
- Field aliases written together on metadata updates
- Legacy progress mirror at `trail_progress/{uid}` when `trailId == activeTrail`
- Fixed document id `activeTrail` for generated draft trail
- Unknown persisted enum strings preserved via `Unknown*Snapshot` types (not coerced to defaults)

## Rules

- **No Firebase SDK** imports in `lib/trails/`
- **No UI** dependencies
- **No Trail business policy** in VexCore
- **Do not rename or remove** persisted fields during adapter migration prep

## Migration path

```
Mobile Trail UI → TrailService → Firebase                         (production today)
Mobile Trail UI → TrailService facade → VexTrail → VexCore → Firebase adapters   (next)
```

VexCore contracts and mobile adapters exist. Runtime cutover is documented in `packages/vex_engines/lib/trail/MOBILE_FACADE_MAPPING.md`.
