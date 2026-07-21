// Loads the Maps JavaScript API exactly once after configuration scripts run.
(function () {
  'use strict';

  var loadState = window.vexdaMapsLoadState || {
    error: null,
    errorCode: null,
    errorDetail: null,
  };
  window.vexdaMapsLoadState = loadState;

  var readySettled = false;
  var readyResolve;
  var readyReject;

  window.vexdaMapsReady = new Promise(function (resolve, reject) {
    readyResolve = resolve;
    readyReject = reject;
  });

  function settleReady() {
    loadState.error = null;
    loadState.errorCode = null;
    loadState.errorDetail = null;
    if (readySettled) {
      return;
    }
    readySettled = true;
    readyResolve();
  }

  function resolveApiKey(config) {
    var apiKey = ((config && config.apiKey) || '').trim();
    if (apiKey && apiKey.indexOf('REPLACE') === -1) {
      return apiKey;
    }

    var scripts = document.querySelectorAll(
      'script[src*="maps.googleapis.com/maps/api/js"]',
    );
    for (var i = 0; i < scripts.length; i++) {
      var src = scripts[i].getAttribute('src') || '';
      var match = src.match(/[?&]key=([^&]+)/);
      if (match && match[1]) {
        return decodeURIComponent(match[1]);
      }
    }

    return '';
  }

  function setLoadError(code, summary, detail) {
    loadState.errorCode = code;
    loadState.error = summary || code;
    loadState.errorDetail = detail || null;
    console.error('[Vexda Maps]', code, detail || summary || '');
    if (!readySettled) {
      readySettled = true;
      readyReject(new Error(summary || code));
    }
  }

  function mapConstructorReady() {
    return (
      window.google &&
      window.google.maps &&
      typeof window.google.maps.Map === 'function'
    );
  }

  var importLibraryStarted = false;

  function waitForMapsApi(attempt) {
    if (typeof attempt !== 'number') {
      attempt = 0;
    }

    if (mapConstructorReady()) {
      settleReady();
      return;
    }

    if (
      !importLibraryStarted &&
      window.google &&
      window.google.maps &&
      typeof window.google.maps.importLibrary === 'function'
    ) {
      importLibraryStarted = true;
      window.google.maps
        .importLibrary('maps')
        .then(function () {
          waitForMapsApi(attempt);
        })
        .catch(function (error) {
          setLoadError(
            'import_library_failed',
            'Failed to load Google Maps libraries',
            String(error && error.message ? error.message : error),
          );
        });
      return;
    }

    if (attempt >= 200) {
      setLoadError(
        'maps_api_timeout',
        'Timed out waiting for Google Maps API',
        'google.maps was not available before map widgets initialised.',
      );
      return;
    }

    window.setTimeout(function () {
      waitForMapsApi(attempt + 1);
    }, 50);
  }

  if (mapConstructorReady()) {
    settleReady();
    return;
  }

  var config = window.VEXDA_MAPS_CONFIG || { apiKey: '', mapId: '' };
  var apiKey = resolveApiKey(config);
  var mapId = (config.mapId || '').trim();

  if (!apiKey) {
    setLoadError(
      'missing_api_key',
      'Maps browser API key is not configured',
      'Run dart run tool/ensure_local_platform_config.dart from the repository root to restore web/vexda_maps_config.js, then restart the web app.',
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
    waitForMapsApi();
    return;
  }

  if (window.google && window.google.maps) {
    waitForMapsApi();
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
  script.onload = function () {
    waitForMapsApi(0);
  };
  script.onerror = function () {
    setLoadError(
      'network_failure',
      'Maps JavaScript API script failed to load',
      'Unable to download maps.googleapis.com. Check network connectivity, firewall rules, and Maps JavaScript API billing.',
    );
  };
  document.head.appendChild(script);
})();
