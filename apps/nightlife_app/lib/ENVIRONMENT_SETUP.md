# DrinkSpot Environment Setup

The app now reads Google routing configuration from Flutter `--dart-define` values via:

```dart
AppConfig.routesApiKey
```

## Required key

```text
GOOGLE_ROUTES_API_KEY=your_google_routes_api_key
```

## Quick command-line run

```bash
flutter run -d emulator-5554 --dart-define="GOOGLE_ROUTES_API_KEY=your_google_routes_api_key"
```

## VS Code: avoid typing the key every time

Create this file in the project root, not inside `lib`:

```text
.vscode/launch.json
```

Example:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "DrinkSpot Dev",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "toolArgs": [
        "--dart-define=GOOGLE_ROUTES_API_KEY=your_google_routes_api_key"
      ]
    }
  ]
}
```

Do not commit your real key to a public repository.

## Android Studio: avoid typing the key every time

Run > Edit Configurations > Additional run args:

```text
--dart-define=GOOGLE_ROUTES_API_KEY=your_google_routes_api_key
```

## Production note

Before public release, restrict the API key in Google Cloud to:

- Android package name
- Android SHA-1 certificate
- iOS bundle ID
- Only the APIs DrinkSpot uses
