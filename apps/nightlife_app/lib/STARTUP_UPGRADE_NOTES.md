# Startup Upgrade Notes

This build adds all five requested startup upgrades:

1. Nearby venue preload during splash
   - Added `StartupDataService`.
   - Checks location permission when possible.
   - Preloads up to 100 active venues from Firestore.
   - Sorts venues by distance when location is available.
   - Falls back to deal/crowd scoring when location is unavailable.

2. Premium splash animation
   - Added scale-in, fade-in, slide-up, pulsing logo, orbit dots, and richer gradient branding.

3. Error handling
   - Startup no longer blocks permanently if Firebase, Firestore, or location is slow/unavailable.
   - Shows a continue dialog for longer startup failures.
   - Location denial falls back safely to popular venues.

4. Rotating loading messages
   - Splash cycles through startup messages while loading.
   - Startup service can temporarily override the message with real task status.

5. Navigation structure
   - Added `lib/core/navigation/app_router.dart`.
   - `MaterialApp` now uses `initialRoute` and `onGenerateRoute`.
   - Routes include splash, auth gate, login, register, and home.

Also added Android/iOS location permission descriptions for Geolocator.
