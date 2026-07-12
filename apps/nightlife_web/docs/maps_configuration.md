# Web Maps setup

The Maps JavaScript API key is **not** in Dart source or committed web assets.

## Local development

From the repository root:

```bash
dart run tool/ensure_local_platform_config.dart
```

Edit `web/vexda_maps_config.js` (gitignored) and set `apiKey`, or set `VEXDA_WEB_MAPS_API_KEY` and re-run the setup tool.

Template: `web/vexda_maps_config.example.js`

Then:

```bash
flutter run -d chrome
```

`index.html` loads `vexda_maps_config.js` once; `GoogleMapsWebConfig` in Dart contains setup hints and Console URLs only.

Full documentation: [docs/platform/API_KEYS_SETUP.md](../../../docs/platform/API_KEYS_SETUP.md)
