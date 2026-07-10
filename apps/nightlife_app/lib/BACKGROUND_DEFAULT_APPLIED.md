# Default Background Applied

The Flutter `lib` folder is now prepared to use this image globally:

```txt
assets/backgrounds/background.png
```

`PremiumScaffold` now falls back to `AppBackgrounds.defaultBackground` whenever a screen does not provide its own background image.

All `AppBackgrounds` screen presets currently point to the same `background.png`, so Map, Search, Saved, Business, Account, Venue, Artist and Auth screens will share the same default background for now.

Make sure your root `pubspec.yaml` contains:

```yaml
flutter:
  assets:
    - assets/backgrounds/
```

Then run:

```bash
flutter clean
flutter pub get
flutter run
```
