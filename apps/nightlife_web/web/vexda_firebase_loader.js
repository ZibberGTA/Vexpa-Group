// Authoritative Firebase web bootstrap for Vexda.
//
// Loads one static ES-module graph (vexda_firebase_modules.js) and assigns
// every window.firebase_* global FlutterFire expects. Prevents FlutterFire
// from dynamically importing the same modules concurrently on WebKit.
(function () {
  'use strict';

  var EXPECTED_VERSION = '11.9.1';
  var REQUIRED_GLOBALS = [
    'firebase_core',
    'firebase_auth',
    'firebase_firestore',
    'firebase_storage',
    'firebase_functions',
  ];

  window.flutterfire_ignore_scripts = [
    'core',
    'auth',
    'firestore',
    'storage',
    'functions',
  ];

  window.vexdaFirebaseLoaderState = {
    version: EXPECTED_VERSION,
    ready: false,
    skipped: false,
    failedService: null,
    errorName: null,
    errorMessage: null,
    loadedSdkVersion: null,
  };

  if (
    REQUIRED_GLOBALS.every(function (globalName) {
      return window[globalName];
    })
  ) {
    window.vexdaFirebaseLoaderState.ready = true;
    window.vexdaFirebaseLoaderState.skipped = true;
    return;
  }

  window.vexdaFirebaseLoaderPromise = import('./vexda_firebase_modules.js')
    .then(function () {
      for (var i = 0; i < REQUIRED_GLOBALS.length; i++) {
        var globalName = REQUIRED_GLOBALS[i];
        if (!window[globalName]) {
          window.vexdaFirebaseLoaderState.failedService = globalName;
          throw new Error('Missing Firebase global: ' + globalName);
        }
      }

      var loadedVersion =
        window.firebase_core && window.firebase_core.SDK_VERSION
          ? window.firebase_core.SDK_VERSION
          : null;
      window.vexdaFirebaseLoaderState.loadedSdkVersion = loadedVersion;

      if (loadedVersion && loadedVersion !== EXPECTED_VERSION) {
        window.vexdaFirebaseLoaderState.failedService = 'sdk_version';
        throw new Error(
          'Firebase SDK version mismatch: expected ' +
            EXPECTED_VERSION +
            ', loaded ' +
            loadedVersion,
        );
      }

      window.vexdaFirebaseLoaderState.ready = true;
    })
    .catch(function (error) {
      window.vexdaFirebaseLoaderState.errorName =
        error && error.name ? error.name : 'Error';
      window.vexdaFirebaseLoaderState.errorMessage =
        error && error.message ? error.message : 'Firebase module graph failed';
      throw error;
    });
})();
