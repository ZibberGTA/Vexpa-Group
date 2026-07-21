# Trail Cutover Manual Regression

Use this checklist after TrailService facade changes or before removing
`trail_service_legacy.dart`.

## Rollback

Set `TrailServiceMigrationConfig.useVexTrailFacade = false` and rebuild, or
revert the commit. Legacy direct-Firestore path remains in
`trail_service_legacy.dart`.

## Customer flows

- [ ] Browse Trails — visible list loads, curated featured card still first when present
- [ ] Open Trail detail — metadata, stops, banner render
- [ ] Join Trail — progress created, `started` activity once
- [ ] Resume after relaunch — canonical progress restored; legacy mirror for `activeTrail`
- [ ] Directions — `directions_requested` activity appended once
- [ ] Check in inside radius — progress updated, `arrived` once
- [ ] Check in too far — blocked message unchanged
- [ ] Missing venue location — check-in still allowed
- [ ] Continue — advances stop, `continue_next` or `completed` once
- [ ] Skip — `skipped_stop` or `completed_after_skip` once
- [ ] Complete trail — terminal UI state
- [ ] Completed trail — no further mutations

## Admin flows

- [ ] Staff trail list — all trails, newest first
- [ ] Create draft — new document id returned
- [ ] Edit metadata — aliases preserved (`name`/`title`, availability fields)
- [ ] Edit stops — 1-based order, availability derived from stops
- [ ] Publish — uses legacy-compatible path (no readiness gate)
- [ ] Unpublish — draft-like state
- [ ] Archive / disable — archived semantics
- [ ] Duplicate — copy suffix, draft reset
- [ ] Delete — document removed (founder rules)
- [ ] Generated draft — `activeTrail` replace when invoked

## Firestore verification

For a test user and trail, confirm:

| Path | Expected |
| --- | --- |
| `trails/{id}` | Aliases, embedded stops, publication fields |
| `users/{uid}/trail_state/active` | `activeTrailId`, server `updatedAt` |
| `users/{uid}/trails/{id}/progress/current` | Canonical progress, list-index `currentStop` |
| `trail_progress/{uid}` | Mirror only when trail id is `activeTrail` |
| `trail_activity/{id}` | Append-only, exact action strings, no duplicates on retry |

## Event bus

Trail domain events publish after successful writes. No Trail event subscribers
exist in the mobile app today — events are in-process only and do not trigger UI,
notifications, or duplicate activity writes.

## Known preserved weaknesses

- Client-side geofence validation separate from write path
- Full-collection trail reads
- Admin publish bypasses publication readiness checklist
- Activity append is not idempotent on retry
