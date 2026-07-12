# Vexda platform API keys

Provider-specific Google Maps and Routes credentials live **outside VexCore** in untracked local files or CI environment variables. Firebase-generated configuration (`firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`) is separate and must not be edited for Maps.

## One-time setup after clone

From the repository root:

```bash
dart run tool/ensure_local_platform_config.dart
```

Then place your keys in the local files below (never commit real values).

## Local development

### Android Maps — `VEXDA_ANDROID_MAPS_API_KEY`

Add to `apps/nightlife_app/android/local.properties` (gitignored):

```properties
VEXDA_ANDROID_MAPS_API_KEY=your_android_maps_sdk_key
```

Flutter creates `local.properties` on first Android run; merge the line above into that file.

Alternatively set the environment variable `VEXDA_ANDROID_MAPS_API_KEY` before `flutter run`.

Resolution order in Gradle: environment variable → `local.properties` → `-PMAPS_API_KEY` → empty (warning logged).

Template: `apps/nightlife_app/android/local.properties.example`

### Mobile Routes — `VEXDA_ROUTES_API_KEY`

Edit `apps/nightlife_app/lib/core/config/app_secrets.local.dart` (gitignored):

```dart
const String kLocalRoutesApiKey = 'your_routes_api_key';
```

Template: `app_secrets.local.dart.example`

Precedence in `AppConfig.routesApiKey`:

1. `--dart-define=GOOGLE_ROUTES_API_KEY=...` (CI/release override)
2. `app_secrets.local.dart`
3. Empty (in-app routes show existing error + external Maps fallback)

### Web Maps — `VEXDA_WEB_MAPS_API_KEY`

Copy `apps/nightlife_web/web/vexda_maps_config.example.js` to `web/vexda_maps_config.js` (gitignored) and set `apiKey`.

Production HTTP referrer restrictions should include:

- `https://vexda.co.uk/*`
- `https://www.vexda.co.uk/*`
- `https://nightlife-app-19acd.web.app/*`
- `https://nightlife-app-19acd.firebaseapp.com/*`
- `http://localhost:*` and `http://127.0.0.1:*` for development

### iOS Maps — `VEXDA_IOS_MAPS_API_KEY` (macOS)

Copy `apps/nightlife_app/ios/Flutter/Secrets.xcconfig.example` to `Secrets.xcconfig` (gitignored):

```text
MAPS_API_KEY=your_ios_maps_sdk_key
```

`Debug.xcconfig` / `Release.xcconfig` include it via `#include?`. Bundle identifier remains `com.drinkspot.app`.

## Ordinary workflow

After local files are configured once:

```bash
cd apps/nightlife_app && flutter run
cd apps/nightlife_web && flutter run -d chrome
```

No `--dart-define` or Git Bash key typing required for day-to-day development.

## CI / release

Generate all local files from environment variables before build:

```bash
export VEXDA_ANDROID_MAPS_API_KEY=...
export VEXDA_ROUTES_API_KEY=...
export VEXDA_WEB_MAPS_API_KEY=...
export VEXDA_IOS_MAPS_API_KEY=...

dart run tool/ensure_local_platform_config.dart

cd apps/nightlife_app && flutter build apk --release
cd apps/nightlife_web && flutter build web --release
```

Optional Routes override for a single build:

```bash
flutter build apk --dart-define=GOOGLE_ROUTES_API_KEY=...
```

## Credential separation

| Credential | Purpose |
| --- | --- |
| `VEXDA_ANDROID_MAPS_API_KEY` | Maps SDK for Android |
| `VEXDA_IOS_MAPS_API_KEY` | Maps SDK for iOS |
| `VEXDA_WEB_MAPS_API_KEY` | Maps JavaScript API (browser key) |
| `VEXDA_ROUTES_API_KEY` | Google Routes API (`computeRoutes`) on mobile |
| Firebase keys in `firebase_options.dart` | Firebase SDK only — do not reuse for Maps |

## Hygiene

The repository includes an automated test that fails if a non-Firebase `AIza` key is committed. Only Firebase-generated client keys may remain in tracked files.
