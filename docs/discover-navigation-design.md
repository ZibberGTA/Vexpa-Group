# Discover Navigation Design

## Purpose of Discover

Discover is the map-led exploration tab in the Vexda mobile app. It helps users visually explore venues, deals, and events through an interactive map without duplicating the dedicated Search tab.

Discover is optimised for a **short nearest list** of venues, deals, and events around the user’s physical location. Search remains the place for broader text-led discovery, advanced filters, and larger result sets.

The bottom navigation already labels this tab **Discover**. The map screen does not repeat a visible page title; filter controls and the search field begin at the top of the map overlay. Screen identity is still exposed through accessibility semantics.

## Bottom navigation order

The main shell uses five tabs in this exact order:

1. **Discover** (map-led exploration)
2. **Search** (text-led discovery)
3. **Trails** (centre action)
4. **Saved** (favourites)
5. **Account**

Business/manage tools for venue owners and staff are accessed from Account rather than the bottom bar.

## Centre Trails button

The Trails tab uses a visually dominant centre button:

- Circular purple outline in the default state
- Route icon and **Trails** label
- Slightly larger than the side navigation items

### Glow rules

The Trails button glows only when the user has an **actively started and incomplete** joined trail:

- Condition: `progress.started && !progress.completed`
- Upcoming (joined but not started) trails do **not** glow
- Completed trails do **not** glow

Glow uses a subtle animated pulse and respects reduced-motion accessibility settings (`MediaQuery.disableAnimations`).

The old top-left **Tonight's Trails** map chip has been removed. Trails entry is only via the centre navigation button.

## Discover quick filters

Three pill filters sit above the Discover search bar in this order:

| Filter | Behaviour |
|---|---|
| **Deals** | Returns up to **10** closest public venues with at least one active, publicly visible deal |
| **Events** | Returns up to **10** closest public venues with at least one active/upcoming public event |
| **Venues** | Returns up to **10** closest eligible public venues |

Quick-filter results are sorted by **distance from the user’s location**, not the map centre or visible viewport. Panning or zooming the map does **not** change the active quick-filter list.

Only one primary filter is selected at a time. Tapping the active filter again deselects it and closes the results panel. Switching filters replaces panel content without stacking panels.

### Qualification and ordering

- **Deals:** query active public deals, deduplicate to one venue per deal set, compute distance from user coordinates, sort nearest-first with deterministic name/id tie-breakers, limit to `DiscoverFilter.discoverQuickResultLimit` (10)
- **Events:** query upcoming public events, keep the soonest event per venue for card context, sort primarily by distance (event time is secondary within equal distances), limit to 10
- **Venues:** include eligible searchable public venues with valid coordinates, sort nearest-first, limit to 10

Venues outside the visible map area may appear if they are among the nearest qualifying results. Venues inside the viewport are excluded when farther than the nearest 10.

### Location resolution

Location is resolved in priority order:

1. Cached startup location (`StartupCache`)
2. One cached device-location read via `DeviceLocationService` (no repeated permission prompts during rebuilds)
3. Existing permission and location-service checks through `Geolocator` when the user explicitly recentres

### Map bootstrap camera

Discover map initial camera target (`MapBootstrapLocation`):

1. Startup/device location when available
2. Geographic centroid of preloaded venues with coordinates
3. `MapBootstrapLocation.applicationFallbackCenter` — UK geographic centroid (last resort only; not Edinburgh/London as a normal launch default)

When startup had no GPS, the map performs a **single** post-create recenter if a cached device location becomes available without requesting permission again. Manual map movement is not overridden by search refreshes (`MapCameraPolicy`).

If location cannot be resolved, the results panel shows an appropriate state and **does not** fall back to map-bounds results:

- Permission denied
- Location services disabled
- Temporary lookup failure

### Location failure copy

- Permission denied: *Allow location access to see the closest venues.*
- Services disabled: *Turn on location services to find venues near you.*
- Temporary failure: *We couldn't determine your location. Please try again.*

## Discover text search

The Discover map search field filters venue markers by text via `MapDiscoveryService.loadVenuesForSearch`. It does not replace the Search tab's richer `SearchService` flow.

Map panning and zooming are exploratory only — they do **not** show a refresh prompt, mark results stale, or trigger map-area search UI. Use the Search tab for broader discovery.

## Presentation state

Transient Discover UI is coordinated by `DiscoverPresentationState` in `venue_map_screen.dart`:

- Selected filter
- Results load state and panel expanded/collapsed
- `panelShown` — drives enter/exit animation while a filter remains active during dismiss
- Selected result venue id (map/card sync while panel is open)
- Venue preview sheet open flag

Derived getters prevent invalid combinations:

- `resultsPanelVisible` — filter selected, panel shown, and venue preview closed
- `shouldHideMapControls` — active filter dismiss in progress or venue preview open
- `hasSelectedVenueInResults` — selected venue id exists in the current result list

## Results panel

When Deals, Events, or Venues is selected:

- A bottom panel **slides up** from below the navigation inset (280ms ease-out) with a subtle fade-in
- On dismiss, the panel **slides down** and fades out (240ms ease-in) before state is cleared
- Under **reduced motion** (`MediaQuery.disableAnimations`), the panel appears and disappears instantly with no movement
- Switching filters while the panel is open keeps the panel mounted and transitions content via `AnimatedSwitcher` rather than closing and reopening
- The panel uses Vexda dark surface styling: `AppColors.card` with slight transparency, purple border, rounded corners, and restrained purple ambient shadow
- The panel can collapse/expand while preserving filter state until the filter is cleared
- Headers show contextual titles: `Closest deals`, `Closest events`, `Closest venues`
- Subtitle: `Showing up to 10 nearest venues`
- Empty states reference the user’s location, not the map viewport
- A small footer may say: *Looking for more? Use Search*

Only the panel layer is animated; the Google Map and bottom navigation are not rebuilt per animation frame.

### Filter pill styling

The active Deals, Events, or Venues pill uses stronger Vexda purple emphasis:

- Deeper purple-tinted fill
- Brighter purple border and restrained purple glow
- Brighter icon and label (fixed weight to avoid layout shift)
- Optional purple selected dot

Unselected pills remain on a darker transparent surface with subtle borders.

### Dismissal

- Tapping the active filter again closes the panel
- Tapping empty map background (not a marker, control, or overlay) clears the filter and closes the panel
- Selecting a venue from a card or marker closes the results panel before opening the venue preview
- Leaving the Discover tab resets presentation state; returning shows a clean full-map view

Right-side map controls (zoom, location, satellite, etc.) are hidden while filter results or a venue preview are visible, and restored when those overlays close.

## Venue cards and map sync

Results use **portrait venue cards** in a horizontal carousel backed by a retained `ScrollController`:

- Responsive width (~44% of viewport, clamped) so a partial next card peeks on typical phone widths
- Carousel scrolls inside a **permanently inset viewport**: outer horizontal `Padding` defines the gutter (aligned with header/footer via `DiscoverCarouselScroll.panelContentPadding`, 16 logical px), and an inner `ClipRRect` clips cards so they never paint into the gutter or against the panel border
- ListView horizontal padding alone is insufficient — it only spaces the first/last items; the scrollable viewport itself must be inset
- First card starts at scroll offset 0 inside the clipped viewport; marker scroll offsets exclude the outer inset
- Venue image, name, distance, rating, open status, and filter-specific context
- Favourite action per card
- Card tap selects the marker, optionally focuses the camera, closes the results panel, then opens the venue preview/details flow

**ScrollController safety:** exactly one controller-backed horizontal `ListView` is mounted while the panel is expanded. Loading, empty, and error overlays animate separately via `AnimatedSwitcher` and never attach the carousel controller. Filter changes update carousel data in place rather than building duplicate scroll views.

### Marker → carousel

When the results panel is open and the user taps a marker belonging to the active result set:

1. The matching venue id becomes the selected result
2. The carousel smoothly scrolls to that card (offset = index × (card width + spacing); the outer viewport inset is not included in scroll offsets)
3. The marker is raised to the front via `zIndex` (same artwork and size as other markers)
4. After a brief scroll beat (~120ms), the existing venue-preview flow runs

Marker taps outside the active result set skip carousel scrolling and open the venue directly.

### Card → marker

When the user taps a venue card:

1. The selected venue id updates
2. The corresponding marker is raised to the front via `zIndex`
3. The map camera focuses the venue when supported
4. The results panel animates closed before the venue preview opens

Scroll position is clamped when filters change or results reload. Scrolling the carousel alone does not open venues.

### Selected marker treatment

Only **one** marker may appear selected at a time.

Selected markers use the **same bitmap artwork and size** (200px) as all other markers. Selection is indicated by raising the marker with a higher `zIndex` so it renders above neighbours. There are no enlarged variants, selection-specific glows, coloured rings, or separate cached bitmaps for selected state.

Filter-based marker glow (deals = purple, events = cyan, busy/packed crowd on Venues) remains independent of selection and uses the standard marker cache keyed by venue artwork and filter context.

Marker sets refresh when selection, filter, or underlying venue data changes — not on every carousel scroll or panel animation frame.

The selected marker returns to the normal stacking order when another venue is selected, the filter clears, the panel dismisses, the preview closes, the user leaves Discover, or the venue is no longer in the active result list.

Map pins and cards stay synchronised while the panel is open:

- The first result is selected on load and the camera fits the returned venues (and user location when available)
- Filter-context glow colours still apply where configured (deals = purple, events = cyan)
- Marker artwork remains a fixed size; selection uses `zIndex` only

Search tab remains the destination for more venues, wider coverage, drinks/venue-name lookup, and advanced filters. Discover stops at 10 and does not auto-navigate to Search.

## Tab lifecycle

`MainNavigationScreen` uses an `IndexedStack`, so the Discover map widget stays alive when switching tabs. When `discoverTabActive` becomes false, `VenueMapScreen` resets transient presentation state (filter, panel, selection, preview). Cached venue data and map camera position are preserved.

## Safe area

The bottom navigation and Discover results panel both respect `SafeArea` and use the measured navigation bar height plus device insets so labels and panel content are not clipped on gesture navigation, three-button Android navigation, or iPhone home indicators.
