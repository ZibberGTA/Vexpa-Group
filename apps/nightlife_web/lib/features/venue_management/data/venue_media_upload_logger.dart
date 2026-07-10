import 'package:flutter/foundation.dart';

import 'venue_media_upload_errors.dart';

/// Debug logging for venue media upload failures.
class VenueMediaUploadLogger {
  VenueMediaUploadLogger._();

  static const _tag = '[VenueMediaUpload]';

  static void logRollback({required String storagePath, Object? error}) {
    if (!kDebugMode) return;
    debugPrint('$_tag rollback storage delete → $storagePath (cause: $error)');
  }

  static void logFailure(VenueMediaUploadException error) {
    if (!kDebugMode) return;
    debugPrint('$_tag upload failed kind=${error.kind}');
    debugPrint('$_tag userMessage=${error.userMessage}');
    debugPrint('$_tag devDetails=${error.devDetails}');
    if (error.cause != null) debugPrint('$_tag cause=${error.cause}');
    if (error.stackTrace != null) {
      debugPrint('$_tag stackTrace:\n${error.stackTrace}');
    }
  }
}
