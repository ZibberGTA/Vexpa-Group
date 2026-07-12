# DrinkSpot / Vexda mobile environment setup

Platform API keys (Maps, Routes) are documented in:

**[docs/platform/API_KEYS_SETUP.md](../../docs/platform/API_KEYS_SETUP.md)**

## Quick start

From the repository root:

```bash
dart run tool/ensure_local_platform_config.dart
```

Then configure:

- **Android Maps:** `apps/nightlife_app/android/local.properties` → `VEXDA_ANDROID_MAPS_API_KEY`
- **Routes:** `apps/nightlife_app/lib/core/config/app_secrets.local.dart` → `kLocalRoutesApiKey`
- **iOS Maps (macOS):** `apps/nightlife_app/ios/Flutter/Secrets.xcconfig` → `MAPS_API_KEY`

After that, ordinary development is:

```bash
flutter run
```

## Routes override (CI)

`--dart-define=GOOGLE_ROUTES_API_KEY=...` still overrides the local Routes key when needed.

## Production note

Restrict each Google Cloud API key to the minimum APIs and platform identifiers (Android package + SHA-1, iOS bundle, web referrers).
