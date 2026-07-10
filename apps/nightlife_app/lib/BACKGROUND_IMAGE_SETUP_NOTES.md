# Background Image Setup

The lib folder is now prepared for screen-specific background images.

Add your images to the project root here:

```txt
assets/backgrounds/
```

Recommended filenames:

```txt
map_bg.jpg
search_bg.jpg
saved_bg.jpg
business_bg.jpg
account_bg.jpg
venue_bg.jpg
artist_bg.jpg
auth_bg.jpg
```

Then add this to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/backgrounds/
```

The bottom navigation screens now automatically use:

- Map: `assets/backgrounds/map_bg.jpg`
- Search: `assets/backgrounds/search_bg.jpg`
- Saved: `assets/backgrounds/saved_bg.jpg`
- Business/Manage: `assets/backgrounds/business_bg.jpg`
- Account: `assets/backgrounds/account_bg.jpg`

If an image is missing, the app will not crash. It will simply fall back to the normal dark premium background.

To manually use a background on any screen:

```dart
PremiumScaffold(
  backgroundImage: AppBackgrounds.venue,
  body: ...,
)
```

Import:

```dart
import '../../core/theme/app_backgrounds.dart';
```
