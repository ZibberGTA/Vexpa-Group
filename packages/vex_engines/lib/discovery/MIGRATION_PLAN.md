# Discovery Engine Migration Plan

Classification tags:

| Tag | Meaning |
| --- | --- |
| **DISC** | Discovery Engine |
| **VC** | VexCore |
| **WEB** | Web app shell / adapters |
| **MOB** | Mobile app shell |
| **VE** | Venue Engine |
| **OTHER** | Another future engine |
| **DECIDE** | Needs product/architecture decision |

## Web search audit (`apps/nightlife_web/lib/features/search/`)

| File | Tag | Phase 1 batch | Notes |
| --- | --- | --- | --- |
| `data/search_text_utils.dart` | DISC | Migrated | Re-export shim |
| `data/venue_search_matcher.dart` | DISC | Migrated | Uses `DiscoveryVenueSearchable` |
| `data/search_ranking.dart` | DISC | Migrated | Re-export shim |
| `data/search_venue_filter.dart` | DISC | Migrated | Re-export shim |
| `data/search_venue_open_status.dart` | DISC | Migrated | Re-export shim |
| `models/search_match_models.dart` | DISC/WEB | Split | Engine owns DTOs; web owns `matchLine` |
| `models/venue_search_result.dart` | WEB | Later | Implements `DiscoveryVenueMatchable`; UI gradients/map |
| `data/search_venue_mapper.dart` | WEB | Later | Split presentation mapping |
| `data/search_venue_catalog.dart` | WEB | — | App catalog wrapper |
| `data/search_repository.dart` | WEB | Wired | Facade → Discovery Engine |
| `data/search_venue_repository.dart` | WEB/VC | Wired | VexCore catalog load |
| `data/sources/venue_search_data_source.dart` | WEB | Wired | Delegates merge to engine |
| `data/unified_search_service.dart` | WEB | Wired | Firestore entity queries stay; composition in engine |
| `data/search_preview_data.dart` | WEB | — | Dev fixtures |
| `data/search_autocomplete_data.dart` | WEB | — | UI autocomplete |
| `data/search_map_coordinates.dart` | WEB | — | Google Maps |
| `data/search_venue_map_geometry.dart` | WEB | — | Map centre |
| `map/search_map_marker_*.dart` | WEB | — | Map markers |
| `screens/*.dart` | WEB | Phase 4 | Pages stay in web |
| `widgets/*.dart` | WEB | Phase 4 | Widgets stay in web |
| `features/home/widgets/hero_search_panel.dart` | WEB | — | Navigation only |

## Related web files

| File | Tag | Notes |
| --- | --- | --- |
| `features/venue/data/venue_related_repository.dart` | DISC | Similar/nearby scoring — next batch |
| `core/vexcore/web_vexcore.dart` | WEB | Discovery service composition root |

## Mobile audit

| File | Tag | Notes |
| --- | --- | --- |
| `features/search/services/search_service.dart` | DISC/MOB | Split: pure logic → engine; Firestore → app |
| `features/search/services/search_index_service.dart` | DISC/VE | Align term building with Venue Engine |
| `features/search/screens/search_screen.dart` | MOB | UI |
| `features/map/screens/venue_map_screen.dart` | MOB | UI; extract open-status/bounds helpers later |
| `features/recommendations/services/venue_recommendation_service.dart` | DISC | Scorer extraction — next batch |
| `features/trending/services/trending_service.dart` | DISC | Scorer extraction — next batch |

## Migrated in this batch

- `SearchTextUtils`
- `VenueSearchMatcher`
- `SearchRanking`
- `SearchFilterCategory` + `SearchVenueFilter`
- `SearchVenueOpenStatus`
- `MatchedDrink/Deal/Event/Trail`, `SearchGroupCounts`
- `DiscoveryVenueSearchService`
- `DiscoveryUnifiedSearchComposer`
- `DiscoveryVenueIndexRepository` (contract)

## Network calls (venue search path)

| Step | Before | After |
| --- | --- | --- |
| Catalog load (`loadCatalog`) | 1 × `VenueDataService.loadDiscoveryCatalog` | Same |
| Venue index search (non-empty query) | 1 × `VenueDataService.searchDiscoveryVenues` | Same |
| Cross-entity Firestore queries | Unchanged in `UnifiedSearchService` | Unchanged |

No extra listeners or duplicate catalog fetches were introduced.

## Migrated in Batch 2

- `DiscoveryRelatedVenueService` (similar + nearby scoring)
- `DiscoveryGeoUtils` / `DiscoveryMapBounds`
- `DiscoverySearchTermIndexer`
- `DiscoveryVenueFilterRules`, `DiscoveryMobileSearchMerger`, `DiscoveryMobileSearchRanking`
- `DiscoveryTrendingScorer` + `DiscoveryBoostEvaluator`
- `DiscoveryRecommendationScorer`

Mobile adoption:

- `SearchService` → shared text utils, filters, merge, ranking
- `SearchIndexService` → shared term indexer
- `TrendingService` → shared trending scorer
- `VenueRecommendationService` → shared recommendation scorer
- `VenueMapScreen` → shared query terms + bounds helpers

## Network calls (Batch 2)

| Flow | Before | After |
| --- | --- | --- |
| Related venues | 1 catalog load | Same — 1 catalog load |
| Mobile search | Firestore queries unchanged | Same query pattern |
| Trending | venues + boosts + analytics per venue | Same |
| Recommendations | venue stream + deals/events per venue | Same |

## Next batch (recommended)

1. VexCore cross-entity discovery read contracts; remove direct Firestore from `UnifiedSearchService`
2. Mobile `SearchService` venue-direct search path convergence with web index flow
3. Presentation phase: search pages/widgets under `presentation/web/` and `presentation/mobile/`
4. Recommendation/trending input DTOs fed from VexCore analytics contracts

## Rollback

Revert web shims to inline implementations and remove `WebVexCore.discoveryVenueSearchService` wiring.
Engine package exports can remain without runtime impact.
