# Maps tile seam investigation (web)

**Status:** Resolved by migrating to Google Cloud Vector Maps.

## Symptom

Grey horizontal/vertical lines forming large squares on the Vexda web map. Lines moved on pan, disappeared at some zoom levels, and did not block labels or roads.

## Root cause (confirmed)

1. Vexda web used the default **raster** Maps JavaScript API renderer (`google.maps.Map` on a `<div>` without Cloud `mapId`).
2. The map base was a grid of **256×256 px `<img>` tiles** from `maps.googleapis.com/vt`.
3. **Sub-pixel tile positioning** (fractional container width, browser zoom ≠ 100%, compositor rounding) exposed 1 px gaps between adjacent raster tiles.
4. Vexda’s **near-uniform dark styling** (`#111218`) made those gaps appear as light grey seam lines.

This was **not** a Flutter overlay, data grid, or CSS border artefact.

## Evidence

Automated DOM analysis (`web/maps_tile_diagnostic.html`, `tool/run_maps_tile_diagnostic.mjs`):

| Measurement | Raster (before) |
| --- | --- |
| `map.getRenderingType()` | `RASTER` |
| Raster tile `<img>` count | 20 |
| Canvas count | 0 |
| Tile size | 256×256 px |
| Fractional shell (979.5 px) | 20/20 tiles with sub-pixel `left` |

## Fix applied

- Created Cloud Map Style `docs/cloud_map_style/vexda_web_dark.json`
- Shared Cloud Vector Map ID via `VexdaCloudMapConfig.mapId`
- All web `GoogleMap` widgets use `mapId` only (no JSON `styles:`)
- Removed raster seam workarounds:
  - `index.html` `.gm-style` border CSS
  - `VexdaGoogleMapSurface` integer sizing wrapper
  - Web `DarkMapStyle` JSON class

## Verification

Run after configuring `VEXDA_WEB_MAPS_MAP_ID`:

```bash
cd apps/nightlife_web
node tool/run_maps_vector_verification.mjs
```

Expected: `getRenderingType: VECTOR`, `rasterTileImgCount: 0`, `gmStyleCanvasCount >= 1`.

## Browser fallbacks

Vector maps require WebGL / hardware acceleration. Google may fall back to **raster** when:

- Hardware acceleration is disabled (Chrome/Edge Settings → System)
- WebGL is unavailable (some headless/CI environments)
- Mobile web on unsupported devices (experimental vector support)

Monitor with `map.getRenderingType()` and the `renderingtype_changed` event.

## Diagnostic assets (retained)

- `web/maps_tile_diagnostic.html` — full-viewport map + DOM report
- `tool/run_maps_tile_diagnostic.mjs` — raster seam regression harness
- `tool/run_maps_vector_verification.mjs` — vector migration verification
