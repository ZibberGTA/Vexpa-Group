// Vexda Google Maps load state and runtime error detection (committed — no secrets).
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

  function classifyMapsConsoleError(message) {
    if (message.indexOf('RefererNotAllowedMapError') !== -1) {
      return {
        code: 'referrer_denied',
        summary: 'Maps API referrer restriction blocked this page',
        detail:
          'The browser Maps API key does not allow the current origin. Add this site to HTTP referrer restrictions in Google Cloud Console.',
      };
    }
    if (message.indexOf('ApiNotActivatedMapError') !== -1) {
      return {
        code: 'api_disabled',
        summary: 'Maps JavaScript API is not enabled',
        detail:
          'Enable Maps JavaScript API for GCP project nightlife-app-19acd and confirm billing is active.',
      };
    }
    if (message.indexOf('InvalidKeyMapError') !== -1) {
      return {
        code: 'invalid_api_key',
        summary: 'Maps API key is invalid',
        detail:
          'The configured browser Maps API key was rejected by Google. Verify VEXDA_WEB_MAPS_API_KEY and the key restrictions.',
      };
    }
    if (message.indexOf('RequestDeniedError') !== -1) {
      return {
        code: 'request_denied',
        summary: 'Maps API request was denied',
        detail:
          'Google denied the Maps JavaScript API request. Check API enablement, billing, and key restrictions.',
      };
    }
    if (
      message.indexOf('BillingNotEnabled') !== -1 ||
      message.indexOf('billing') !== -1
    ) {
      return {
        code: 'billing_failure',
        summary: 'Maps API billing is not enabled',
        detail:
          'Confirm billing is enabled for GCP project nightlife-app-19acd.',
      };
    }
    if (message.indexOf('Google Maps JavaScript API error') !== -1) {
      return {
        code: 'maps_api_error',
        summary: message,
        detail: message,
      };
    }
    return null;
  }

  window.gm_authFailure = function () {
    if (loadState.errorCode) {
      return;
    }
    setLoadError(
      'auth_failure',
      'Google Maps authentication failed',
      'Maps JavaScript API authentication failed. Verify the browser API key, enable Maps JavaScript API, confirm billing, and allow this origin in referrer restrictions.',
    );
  };

  (function () {
    var originalError = console.error;
    console.error = function () {
      var message = Array.prototype.join.call(arguments, ' ');
      var classified = classifyMapsConsoleError(message);
      if (classified) {
        setLoadError(
          classified.code,
          classified.summary,
          classified.detail,
        );
      }
      originalError.apply(console, arguments);
    };
  })();
})();
