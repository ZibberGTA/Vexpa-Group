import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'vexda_firebase_web_config.dart';

@JS('globalThis')
external JSObject get _globalContext;

@JS('window.vexdaFirebaseLoaderPromise')
external JSPromise<JSAny?>? get _firebaseLoaderPromise;

bool _hasFirebaseWebGlobal(String windowGlobal) {
  return _globalContext.getProperty(windowGlobal.toJS) != null;
}

Future<void> waitForFirebaseWebModuleGraph({
  Duration timeout = const Duration(seconds: 20),
}) async {
  final loaderPromise = _firebaseLoaderPromise;
  if (loaderPromise != null) {
    try {
      await loaderPromise.toDart.timeout(timeout);
    } on TimeoutException {
      throw StateError('Firebase module graph timed out');
    } on Object {
      final failedService = readFirebaseWebLoaderFailedService();
      if (failedService != null) {
        throw StateError('Firebase module missing: $failedService');
      }
      rethrow;
    }
  } else {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_moduleGraphComplete()) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  if (!_moduleGraphComplete()) {
    final missing = _firstMissingModule();
    throw StateError(
      'Firebase module missing: ${missing?.windowGlobal ?? 'unknown'}',
    );
  }

  final loadedVersion = readFirebaseWebLoaderLoadedSdkVersion();
  if (loadedVersion != null &&
      loadedVersion != kVexdaFirebaseJsSdkVersion) {
    throw StateError(
      'Firebase SDK version mismatch: expected $kVexdaFirebaseJsSdkVersion, loaded $loadedVersion',
    );
  }
}

bool _moduleGraphComplete() {
  for (final module in kVexdaFirebaseWebModules) {
    if (!_hasFirebaseWebGlobal(module.windowGlobal)) {
      return false;
    }
  }
  return true;
}

VexdaFirebaseWebModule? _firstMissingModule() {
  for (final module in kVexdaFirebaseWebModules) {
    if (!_hasFirebaseWebGlobal(module.windowGlobal)) {
      return module;
    }
  }
  return null;
}

@JS('window.vexdaFirebaseLoaderState')
external _FirebaseLoaderState? get _firebaseLoaderState;

extension type _FirebaseLoaderState._(JSObject _) implements JSObject {
  external String? get failedService;
  external String? get loadedSdkVersion;
}

String? readFirebaseWebLoaderFailedService() {
  return _firebaseLoaderState?.failedService;
}

String? readFirebaseWebLoaderLoadedSdkVersion() {
  return _firebaseLoaderState?.loadedSdkVersion;
}

Future<void> reloadApplicationClearingServiceWorkers() async {
  final serviceWorker = web.window.navigator.serviceWorker;
  final registrations = await serviceWorker.getRegistrations().toDart;
  for (final registration in registrations.toDart) {
    await registration.unregister().toDart;
  }

  await _clearVexdaWebCaches();

  final url = web.URL(web.window.location.href);
  url.searchParams.set(
    'vexda_reload',
    DateTime.now().millisecondsSinceEpoch.toString(),
  );
  web.window.location.href = url.toString();
}

Future<void> _clearVexdaWebCaches() async {
  final caches = web.window.caches;

  try {
    final keys = await caches.keys().toDart;
    for (final key in keys.toDart) {
      final keyString = key.toString();
      if (keyString.contains('flutter') || keyString.contains('vexda')) {
        await caches.delete(keyString).toDart;
      }
    }
  } on Object {
    // Cache cleanup is best-effort; reload still proceeds.
  }
}
