# Mobile TrailService → VexTrail Facade Mapping

Production `TrailService` (`apps/nightlife_app/lib/features/trails/services/trail_service.dart`) remains the runtime path. This document maps each public method to the new application layer for the future compatibility facade cutover.

## Runtime status

| Layer | Status |
| --- | --- |
| VexTrail application services | Implemented |
| Mobile Firebase adapters | Implemented |
| `TrailServiceFacade` | **Production default** via `TrailServiceMigrationConfig.useVexTrailFacade = true` |
| `TrailServiceLegacy` | Retained for rollback and parity tests |
| Mobile Trail UI | Unchanged — still calls `TrailService` static API |

## Method mapping

| Current method | Parameters | Return | New application service | Adapter / port inputs | Parity notes | Migration risk |
| --- | --- | --- | --- | --- | --- | --- |
| `getTrail` | `trailId` | `Future<DrinkSpotTrailModel?>` | `TrailDiscoveryApplicationService.getTrail` | `TrailRepository.get` | Map domain → UI model in facade | Low |
| `watchTrail` | `trailId` | `Stream<DrinkSpotTrailModel?>` | `TrailRepository.watch` + mapper | Firestore `trails/{id}` | Facade maps snapshot stream | Low |
| `watchStaffTrails` | — | `Stream<List<...>>` | `TrailRepository.watchList` (admin query) | Full collection + client filter | Admin-only; preserve staff filter in facade | Medium |
| `watchVisibleTrails` | — | `Stream<List<...>>` | `TrailDiscoveryApplicationService.watchVisibleTrails` | `TrailRepository.watchList` + visibility policy | Distance sort stays in UI/presentation | Medium |
| `watchActiveTrail` | — | `Stream<DrinkSpotTrailModel?>` | `resolveActiveTrailId` + `watch`/`getTrail` | `users/{uid}/trail_state/active` + `trails/{id}` | Preserve active-state + visible-trail join logic in facade | High |
| `_watchVisibleTrailFallback` | — | internal | Same as `watchVisibleTrails` | — | Internal; facade may inline | Low |
| `watchStaffTrail` | `{trailId}` | `Stream<...?>` | `TrailRepository.watch` | `trails/{id}` | Admin read bypasses public visibility | Low |
| `createTrail` | metadata fields | `Future<String>` | `TrailManagementApplicationService.createDraft` | `TrailRepository.create` | Returns domain trail; facade extracts id | Low |
| `updateTrailMetadata` | metadata fields | `Future<void>` | `TrailManagementApplicationService.updateMetadata` | `TrailRepository.updateMetadata` | Dual alias fields written in adapter | Low |
| `duplicateTrail` | `trailId` | `Future<String>` | `TrailManagementApplicationService.duplicate` | `TrailRepository.duplicate` | Adapter copies document + draft reset | Low |
| `unpublishTrail` | `trailId` | `Future<void>` | `TrailManagementApplicationService.unpublish` | `TrailRepository.unpublish` | Emits `TrailUnpublishedEvent` (new) | Low |
| `archiveTrail` | `trailId` | `Future<void>` | `TrailManagementApplicationService.archive` | `TrailRepository.archive` | Same as disable semantics | Low |
| `deleteTrail` | `trailId` | `Future<void>` | `TrailManagementApplicationService.delete` | `TrailRepository.delete` | Founder-only rules unchanged | Low |
| `generateDraftTrail` | `{trailId}` | `Future<void>` | `TrailGenerationApplicationService.generateAndPersistDraft` | Venue candidates from app + `replaceDocument` | App loads venues; engine scores | Medium |
| `saveTrailStops` | `stops`, `{trailId}` | `Future<void>` | `TrailManagementApplicationService.updateStops` | `TrailRepository.updateStops` | Renumbers 1-based orders | Low |
| `fetchVenueOptions` | — | `Future<List<TrailVenueOption>>` | **App-level** (not VexTrail) | `venues` query in facade/adapter | Keep in facade until venue catalog port exists | Medium |
| `publishTrail` | `{trailId}` | `Future<void>` | **`publishLegacyCompatible`** | `TrailRepository.publish` | Current path skips readiness; facade must use legacy path | **High** |
| `disableTrail` | `{trailId}` | `Future<void>` | `TrailManagementApplicationService.archive` | `TrailRepository.archive` | Alias for archive | Low |
| `watchMyTrailProgress` | `{trailId}` | `Stream<TrailProgressModel?>` | `TrailProgressApplicationService.watchProgress` | `users/{uid}/trails/{trailId}/progress/current` + legacy fallback | Legacy read for `activeTrail` preserved in adapter | Medium |
| `startTrail` | `trail` | `Future<void>` | `TrailProgressApplicationService.join` | batch: active state + progress + legacy mirror | Improved atomicity vs current separate writes | Medium |
| `joinTrail` | `trailId`, `{trail}` | `Future<void>` | `TrailProgressApplicationService.join` | same as start | Anonymous users cannot join (auth required) | Medium |
| `validateStopCheckIn` | `{stop}` | `Future<TrailCheckInValidation>` | **Split**: device location in UI; `TrailCheckInApplicationService.assessEligibility` | `TrailVenueLookupPort` + user coords from UI | Geolocator/permission stays in facade | **High** |
| `checkInAtStop` | trail, stop, index | `Future<void>` | `TrailCheckInApplicationService.checkInAtStop` | progress repo + activity + optional legacy mirror | Backward index no-op preserved in domain | Medium |
| `continueTrail` | trail, stop, index, progress | `Future<int?>` | `TrailProgressApplicationService.continueStop` | progress + activity | Returns next index in facade | Medium |
| `skipStop` | trail, stop, index, progress | `Future<int?>` | `TrailProgressApplicationService.skipStop` | progress + activity | Same | Medium |
| `_readTrailProgress` | internal | internal | `getProgress` / adapter `get` | canonical + legacy | Internal | Low |
| `logTrailDirectionsRequested` | trailId, stop | `Future<void>` | `TrailActivityApplicationService.logDirectionsRequested` | `TrailActivityRepository.append` | Anonymous allowed when signed in | Low |
| `logTrailAction` | action fields | `Future<void>` | `TrailActivityApplicationService.logAction` | `TrailActivityRepository.append` | Exact action strings | Low |

## Publish path guidance

| Operation | Facade method | Enforces readiness |
| --- | --- | --- |
| Admin publish (current behaviour) | `publishLegacyCompatible` | No |
| Validated publish (future default) | `publishValidated` | Yes |

**Do not** switch admin screens to `publishValidated` without explicit product approval.

## Legacy compatibility

- Legacy mirror: `trail_progress/{uid}` when `trailId == activeTrail` (`TrailPaths.activeTrailDocumentId`)
- Activity strings unchanged (`started`, `arrived`, `continue_next`, …)
- Missing venue location → check-in allowed (policy + adapter default radius 75m)
- `currentStop` remains 0-based list index; stop-state keys remain 1-based order

## Tests required before cutover

- [ ] Facade integration test per mapped method
- [ ] Emulator rules test for all adapter write paths
- [ ] Side-by-side parity run against production `TrailService` for join/check-in/continue/skip
- [ ] Admin publish uses legacy-compatible path
- [ ] Event bus subscribers verified (new; production TrailService did not emit domain events)

## Next migration steps

1. Introduce `TrailServiceFacade` implementing the same static API, delegating to `MobileTrailOrchestration`.
2. Feature-flag or `@visibleForTesting` swap behind default-off seam.
3. Map `DrinkSpotTrailModel` ↔ domain `Trail` in the facade only.
4. Move Geolocator permission flow into facade for `validateStopCheckIn`.
5. Cut over one screen at a time; keep production fallback until parity sign-off.
