// Optional local Maps override (copy is not required).
//
// Preferred: set environment variables and run from repo root:
//   export VEXDA_WEB_MAPS_API_KEY=your_browser_maps_key
//   export VEXDA_WEB_MAPS_MAP_ID=your_cloud_vector_map_id
//   dart run tool/ensure_local_platform_config.dart
//
// That writes gitignored web/vexda_maps_config.local.js automatically.
(function () {
  'use strict';

  window.VEXDA_MAPS_CONFIG = Object.assign(window.VEXDA_MAPS_CONFIG || {}, {
    apiKey: '',
    mapId: '',
  });
})();
