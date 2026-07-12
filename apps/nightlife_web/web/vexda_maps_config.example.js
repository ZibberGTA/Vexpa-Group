// Vexda web Maps JavaScript configuration (local — copy from vexda_maps_config.example.js).
// Do not commit real keys. CI generates this file from VEXDA_WEB_MAPS_API_KEY.
//
// Production referrer restrictions should include:
//   https://vexda.co.uk/*
//   https://www.vexda.co.uk/*
//   https://nightlife-app-19acd.web.app/*
//   https://nightlife-app-19acd.firebaseapp.com/*
(function () {
  'use strict';

  var config = {
    apiKey: '',
  };

  var loadState = window.vexdaMapsLoadState || {
    error: null,
    errorDetail: null,
  };
  window.vexdaMapsLoadState = loadState;

  function setMissingConfigError() {
    loadState.error = 'missing_maps_config';
    loadState.errorDetail =
      'Google Maps web key is not configured. Copy web/vexda_maps_config.example.js ' +
      'to web/vexda_maps_config.js and set apiKey, or run ' +
      'dart run tool/ensure_local_platform_config.dart. See docs/platform/API_KEYS_SETUP.md.';
    console.error('[Vexda Maps]', loadState.errorDetail);
  }

  if (!config.apiKey || config.apiKey.indexOf('REPLACE') !== -1) {
    setMissingConfigError();
    return;
  }

  if (document.querySelector('script[data-vexda-maps-loader="true"]')) {
    return;
  }

  var script = document.createElement('script');
  script.setAttribute('data-vexda-maps-loader', 'true');
  script.async = true;
  script.defer = true;
  script.src =
    'https://maps.googleapis.com/maps/api/js?key=' +
    encodeURIComponent(config.apiKey) +
    '&loading=async';
  script.onerror = function () {
    loadState.error = 'Maps JavaScript API script failed to load';
    loadState.errorDetail =
      'Check network access, web/vexda_maps_config.js, and Maps JavaScript API billing.';
    console.error('[Vexda Maps]', loadState.errorDetail);
  };
  document.head.appendChild(script);
})();
