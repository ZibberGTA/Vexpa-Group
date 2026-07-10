import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../firebase_options.dart';

/// Firebase bootstrap for Vexda Web — call [initialize] before [runApp].
class VexdaFirebase {
  VexdaFirebase._();

  static bool _initializeAttempted = false;
  static bool _ready = false;

  /// True when [Firebase.initializeApp] completed and a default app exists.
  static bool get isReady => _ready && Firebase.apps.isNotEmpty;

  static Future<bool> initialize() async {
    if (_initializeAttempted) return isReady;
    _initializeAttempted = true;

    WidgetsFlutterBinding.ensureInitialized();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _ready = true;
      if (kDebugMode) {
        debugPrint('[VexdaFirebase] Initialized (${Firebase.app().name}).');
      }
      return true;
    } on Object catch (error, stackTrace) {
      _ready = false;
      if (kDebugMode) {
        debugPrint('[VexdaFirebase] Initialization failed: $error');
        debugPrint('$stackTrace');
      }
      return false;
    }
  }
}
