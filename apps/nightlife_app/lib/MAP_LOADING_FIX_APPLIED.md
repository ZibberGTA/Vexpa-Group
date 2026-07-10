# Map Loading Fix Applied

Fixed the map loading spinner issue.

## What changed

- Cached the venue-loading Future in `_venuesFuture` instead of recreating `_loadVenues()` on every widget rebuild.
- Search now explicitly refreshes `_venuesFuture` only when the search text changes.
- Clearing search refreshes the cached venue query.
- The pulsing crowd glow timer can still repaint the map without forcing Firestore to reload repeatedly.
- Replaced the blocking center spinner with a small bottom loading card so the map remains usable.

## Why it was happening

The map screen had a `FutureBuilder(future: _loadVenues())` directly inside `build()`. Because the pulsing crowd animation calls `setState()` repeatedly, Flutter kept recreating the Future and querying Firestore again, which caused the loading wheel to keep returning.
