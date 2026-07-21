/// Firebase JavaScript SDK version expected by the resolved [firebase_core_web]
/// package (`supportedFirebaseJsSdkVersion`).
const kVexdaFirebaseJsSdkVersion = '11.9.1';

/// A Firebase web service registered by Vexda's FlutterFire plugins.
class VexdaFirebaseWebModule {
  const VexdaFirebaseWebModule({
    required this.serviceName,
    required this.ignoreScriptName,
    required this.windowGlobal,
    required this.scriptFileName,
    required this.loadedStage,
  });

  /// Human-readable service label used in diagnostics.
  final String serviceName;

  /// Value for [window.flutterfire_ignore_scripts].
  final String ignoreScriptName;

  /// Global assigned before [Firebase.initializeApp] on web.
  final String windowGlobal;

  /// Firebase JS SDK filename under gstatic.
  final String scriptFileName;

  /// Startup stage marked when this global is verified.
  final String loadedStage;
}

/// Every Firebase web plugin registered in `pubspec.yaml` for Vexda Web.
///
/// Sources:
/// - firebase_core_web → core (firebase-app.js)
/// - firebase_auth_web → auth
/// - cloud_firestore_web → firestore
/// - firebase_storage_web → storage
/// - cloud_functions_web → functions
const kVexdaFirebaseWebModules = <VexdaFirebaseWebModule>[
  VexdaFirebaseWebModule(
    serviceName: 'core',
    ignoreScriptName: 'core',
    windowGlobal: 'firebase_core',
    scriptFileName: 'firebase-app.js',
    loadedStage: 'firebaseCoreLoaded',
  ),
  VexdaFirebaseWebModule(
    serviceName: 'auth',
    ignoreScriptName: 'auth',
    windowGlobal: 'firebase_auth',
    scriptFileName: 'firebase-auth.js',
    loadedStage: 'firebaseAuthLoaded',
  ),
  VexdaFirebaseWebModule(
    serviceName: 'firestore',
    ignoreScriptName: 'firestore',
    windowGlobal: 'firebase_firestore',
    scriptFileName: 'firebase-firestore.js',
    loadedStage: 'firebaseFirestoreLoaded',
  ),
  VexdaFirebaseWebModule(
    serviceName: 'storage',
    ignoreScriptName: 'storage',
    windowGlobal: 'firebase_storage',
    scriptFileName: 'firebase-storage.js',
    loadedStage: 'firebaseStorageLoaded',
  ),
  VexdaFirebaseWebModule(
    serviceName: 'functions',
    ignoreScriptName: 'functions',
    windowGlobal: 'firebase_functions',
    scriptFileName: 'firebase-functions.js',
    loadedStage: 'firebaseFunctionsLoaded',
  ),
];

/// Script names passed to `window.flutterfire_ignore_scripts`.
List<String> get kVexdaFlutterFireIgnoreScripts =>
    kVexdaFirebaseWebModules.map((module) => module.ignoreScriptName).toList();

String vexdaFirebaseModuleGraphUrl(String version, String scriptFileName) {
  return 'https://www.gstatic.com/firebasejs/$version/$scriptFileName';
}
