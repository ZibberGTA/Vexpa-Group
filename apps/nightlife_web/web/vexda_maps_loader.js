// Loads the Maps JavaScript API exactly once after configuration scripts run.
(function () {
  'use strict';

  var loadState = window.vexdaMapsLoadState || {
    error: null,
    errorCode: null,
    errorDetail: null,
  };
  window.vexdaMapsLoadState = loadState;

  function setLoadError(code, summary, detail) {
    loadState.errorCode = code;
    loadState.error = summary || code;
    loadState.errorDetail = detail || null;
    console.error('[Vexda Maps]', code, detail || summary || '');
  }

  var config = window.VEXDA_MAPS_CONFIG || { apiKey: '', mapId: '' };
  var apiKey = (config.apiKey || '').trim();
  var mapId = (config.mapId || '').trim();

  if (!apiKey || apiKey.indexOf('REPLACE') !== -1) {
    setLoadError(
      'missing_api_key',
      'Maps browser API key is not configured',
      'Set VEXDA_WEB_MAPS_API_KEY and run dart run tool/ensure_local_platform_config.dart from the repository root, then restart the web app.',
    );
    return;
  }

  var hasMapId = mapId.length > 0 && mapId.indexOf('REPLACE') === -1;
  if (!hasMapId) {
    console.info(
      '[Vexda Maps] Cloud Vector Map ID is not configured — loading raster Maps JavaScript API fallback.',
    );
  }

  if (document.querySelector('script[data-vexda-maps-loader="true"]')) {
    return;
  }

  if (window.google && window.google.maps) {
    return;
  }

  var script = document.createElement('script');
  script.setAttribute('data-vexda-maps-loader', 'true');
  script.async = true;
  script.defer = true;
  var apiUrl =
    'https://maps.googleapis.com/maps/api/js?key=' +
    encodeURIComponent(apiKey) +
    '&loading=async&v=weekly';
  if (hasMapId) {
    apiUrl += '&map_ids=' + encodeURIComponent(mapId);
  }
  script.src = apiUrl;
  script.onerror = function () {
    setLoadError(
      'network_failure',
      'Maps JavaScript API script failed to load',
      'Unable to download maps.googleapis.com. Check network connectivity, firewall rules, and Maps JavaScript API billing.',
    );
  };
  document.head.appendChild(script);
})();
