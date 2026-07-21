# Trail Schema Mapping

Authoritative source: `apps/nightlife_app/lib/features/trails/` (`trail_model.dart`, `trail_service.dart`), `apps/nightlife_app/firestore.rules`, and web read paths in `apps/nightlife_web/`.

Legend:

- **Owner**: `infrastructure` = persisted shape only; `business` = interpretation/rules (belongs in VexTrail/apps)
- **Writer/Reader**: primary mobile production paths unless noted

## Trail document — `trails/{trailId}`

| Firestore field | Snapshot property | Type | Required | Writer | Reader | Legacy alias | Migration note | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| _(document id)_ | `trailId` | String | yes | create | all | — | — | infrastructure |
| `name` | `name` | String | yes | create, updateMetadata, duplicate, generateDraft | fromDoc, admin UI | `title` | Both written on metadata update | infrastructure |
| `title` | `title` | String | yes | updateMetadata, toMap | fromDoc (fallback for name) | alias of `name` | Keep both for compatibility | infrastructure |
| `description` | `description` | String | yes | create, updateMetadata | fromDoc | `subtitle` | — | infrastructure |
| `subtitle` | `subtitle` | String | yes | updateMetadata, toMap | fromDoc (fallback) | alias of `description` | Keep both | infrastructure |
| `bannerImageUrl` | `bannerImageUrl` | String | no | create, updateMetadata | fromDoc, admin UI | — | URL only; no Storage path today | infrastructure |
| `status` | `status` | TrailStatusSnapshot | yes | create, saveStops, publish, unpublish, archive, duplicate | fromDoc, rules | — | Unknown values must not coerce to draft in VexCore | infrastructure |
| `published` | `published` | bool | yes | create, saveStops, publish, unpublish, archive, duplicate | fromDoc, rules, web search | dual with `status` | Visibility is business-owned | infrastructure |
| `area` | `area` | String | no | create, updateMetadata | fromDoc | — | — | infrastructure |
| `availabilityStart` | `availabilityStart` | DateTime | yes | create, saveStops, updateMetadata | fromDoc | `startTime` | saveStops derives from first stop | infrastructure |
| `availabilityEnd` | `availabilityEnd` | DateTime | yes | create, saveStops, updateMetadata | fromDoc | `endTime` | saveStops derives from last stop | infrastructure |
| `startTime` | `startTime` | DateTime | yes | updateMetadata, saveStops, toMap | fromDoc (fallback) | alias of `availabilityStart` | — | infrastructure |
| `endTime` | `endTime` | DateTime | yes | updateMetadata, saveStops, toMap | fromDoc (fallback) | alias of `availabilityEnd` | — | infrastructure |
| `estimatedDurationMinutes` | `estimatedDurationMinutes` | int | no | create (via toMap), updateMetadata, saveStops | fromDoc | — | May differ from end-start if explicit | infrastructure |
| `estimatedWalkingDistance` | `estimatedWalkingDistance` | int | no | create, toMap | fromDoc | — | Not updated by current service writes after create | infrastructure |
| `averageRating` | `averageRating` | double | no | toMap default 0 | fromDoc | — | Read but never written by TrailService | infrastructure |
| `venueCount` | `venueCount` | int | yes | create, saveStops, toMap | fromDoc | — | May differ from `stops.length` | infrastructure |
| `trailType` | `trailType` | TrailTypeSnapshot | yes | create, updateMetadata | fromDoc | — | Unknown values preserved in VexCore | infrastructure |
| `generatedAt` | `generatedAt` | DateTime | yes | create, duplicate, generateDraft | fromDoc, sorting | — | Used for progress staleness (`trailGeneratedAt`) | infrastructure |
| `stops` | `stops` | List\<TrailStopSnapshot\> | no | saveStops, generateDraft, duplicate | fromDoc | embedded array | Future extraction possible | infrastructure |
| `createdAt` | `createdAt` | DateTime? | no | create, duplicate | — | — | Server timestamp at write | infrastructure |
| `updatedAt` | `updatedAt` | DateTime? | no | most writes | — | — | Server timestamp at write | infrastructure |
| `publishedAt` | `publishedAt` | DateTime? | no | publish | — | — | Removed on duplicate | infrastructure |
| `unpublishedAt` | `unpublishedAt` | DateTime? | no | unpublish | — | — | — | infrastructure |
| `archivedAt` | `archivedAt` | DateTime? | no | archive | — | — | Removed on duplicate | infrastructure |
| `disabledAt` | `disabledAt` | DateTime? | no | — (removed on duplicate only) | — | — | Legacy field; `disableTrail()` archives instead | infrastructure |
| `searchTerms` | `searchTerms` | List\<String\> | no | — (not mobile writer) | web unified search | — | Optional SEO/search field | infrastructure |

## Embedded stop — `trails/{trailId}.stops[]`

| Firestore field | Snapshot property | Type | Required | Writer | Reader | Legacy alias | Migration note | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `venueId` | `venueId` | String | yes | saveStops, generateDraft | fromMap | — | Geofence reads venue doc, not stop | infrastructure |
| `venueName` | `venueName` | String | yes | saveStops, generateDraft | fromMap | — | Denormalized snapshot | infrastructure |
| `address` | `address` | String | no | saveStops, generateDraft | fromMap | — | — | infrastructure |
| `bannerImageUrl` | `bannerImageUrl` | String | no | saveStops, generateDraft | fromMap | — | From venue banner/imageUrl | infrastructure |
| `logoUrl` | `logoUrl` | String | no | saveStops, generateDraft | fromMap | — | — | infrastructure |
| `order` | `order` | int | yes | saveStops (reindexed) | fromMap | — | 1-based in service | infrastructure |
| `score` | `score` | int | no | generateDraft | fromMap | — | Generation scoring metadata | infrastructure |
| `arriveAt` | `arriveAt` | DateTime | yes | saveStops, generateDraft | fromMap | — | — | infrastructure |
| `leaveAt` | `leaveAt` | DateTime | yes | saveStops, generateDraft | fromMap | — | — | infrastructure |
| `discountLabel` | `discountLabel` | String | no | saveStops | fromMap | — | — | infrastructure |

**Not persisted on stops today:** stop id, coordinates, check-in radius, active flag, instructions.

## Active trail pointer — `users/{uid}/trail_state/active`

| Firestore field | Snapshot property | Type | Required | Writer | Reader | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| `activeTrailId` | `activeTrailId` | String | yes | join, checkIn | watchActiveTrail | infrastructure |
| `updatedAt` | `updatedAt` | DateTime? | no | join, checkIn | — | infrastructure |

Default when missing: `'activeTrail'` (business default in mobile UI stream).

## Progress — `users/{uid}/trails/{trailId}/progress/current`

| Firestore field | Snapshot property | Type | Required | Writer | Reader | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| `trailId` | `trailId` | String | yes | join, updates | fromDoc | infrastructure |
| `trailGeneratedAt` | `trailGeneratedAt` | DateTime? | no | join, updates | fromDoc, belongsTo | infrastructure |
| `started` | `started` | bool | yes | join, updates | fromDoc | infrastructure |
| `completed` | `completed` | bool | yes | join, updates | fromDoc | infrastructure |
| `currentStop` | `currentStop` | int | yes | join, updates | fromDoc | infrastructure (index, not order) |
| `checkedInStops` | `checkedInStops` | Set\<int\> | yes | join, checkIn | fromDoc | stop **order** values | infrastructure |
| `stopStates` | `stopStates` | Map\<int, TrailStopProgressStateSnapshot\> | no | join, updates | fromDoc | keys are order strings in Firestore | infrastructure |
| `startedAt` | `startedAt` | DateTime? | no | join | — | infrastructure |
| `updatedAt` | `updatedAt` | DateTime? | no | all progress writes | — | infrastructure |
| `completedAt` | `completedAt` | DateTime? | no | checkIn/continue/skip when completed | — | infrastructure |
| `lastCheckedInVenueId` | `lastCheckedInVenueId` | String? | no | checkIn | — | infrastructure |
| `lastCheckedInStopOrder` | `lastCheckedInStopOrder` | int? | no | checkIn | — | infrastructure |

Join uses `set(merge: false)` — full reset. Updates use `set(merge: true)`.

### Legacy mirror — `trail_progress/{uid}`

Same field shape as canonical progress. Written with `merge: true` when `trailId == activeTrail`. Read as fallback when canonical doc missing and `trailId == activeTrail`.

## Activity — `trail_activity/{activityId}`

| Firestore field | Snapshot property | Type | Required | Writer | Reader | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| _(document id)_ | `activityId` | String | yes | auto-id on add | list (future) | infrastructure |
| `trailId` | `trailId` | String | yes | logTrailAction | — | infrastructure |
| `userId` | `userId` | String? | no | logTrailAction | rules | infrastructure |
| `isAnonymous` | `isAnonymous` | bool | yes | logTrailAction | — | infrastructure |
| `action` | `action` | String | yes | logTrailAction | — | see TrailActivityAction | infrastructure |
| `venueId` | `venueId` | String? | no | checkIn, continue, skip, directions | — | infrastructure |
| `stopOrder` | `stopOrder` | int? | no | checkIn, continue, skip, directions | — | infrastructure |
| `createdAt` | `createdAt` | DateTime | yes | logTrailAction | — | server timestamp | infrastructure |

Known actions: `started`, `arrived`, `continue_next`, `completed`, `skipped_stop`, `completed_after_skip`, `directions_requested`.

No update/delete in current mobile implementation.

## Storage paths

| Path | Purpose | Current usage |
| --- | --- | --- |
| _(none)_ | Trail banner artwork | **Not used** — `bannerImageUrl` is external URL string |
| `trails/{trailId}/artwork` (recommended) | Future Storage prefix | Documented in `TrailPaths.trailArtworkStoragePrefix` only |

## Firestore rules assumptions

- `trails`: public read when `status == 'published'` OR `published == true`; admin write level ≥ 30; delete founder only
- `users/{uid}/trail_state/**`, `users/{uid}/trails/**/progress/**`: self read/write
- `trail_progress/{uid}`: self read/write (legacy)
- `trail_activity`: signed-in create; support+ read

## Known schema inconsistencies

1. Dual publication signals: `status` and `published` can disagree; mobile visibility uses both (business rule).
2. `saveTrailStops` forces `status: draft`, `published: false` even for previously published trails.
3. `averageRating` read but never written by mobile TrailService.
4. `disabled` status exists; `disableTrail()` calls `archiveTrail()` instead.
5. `searchTerms` read on web but not written by mobile admin.
6. No server-side visibility query — mobile loads full `trails` collection and filters client-side.
7. No composite indexes for trails in `firestore.indexes.json`.
8. Progress `currentStop` is list index; `checkedInStops`/`stopStates` keys use stop `order` (can diverge if orders gap).
9. Legacy progress mirror only for `trailId == activeTrail`.

## Business-owned behaviour (not VexCore)

- Visibility / discovery filtering (`isVisible`, featured UI ordering)
- Publishing readiness validation
- Stop order validation and geofence check-in rules
- Progress state transitions (`_statesForCheckIn`, `_nextUpcomingStopIndex`, `_trailComplete`)
- Generated draft venue scoring (`generateDraftTrail`)
- Featured trail selection in discovery UI (UI-only `featured` flag, not persisted)
