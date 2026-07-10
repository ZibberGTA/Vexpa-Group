import 'dart:async';
import 'dart:js_interop';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../firebase/firebase_storage_download_url.dart';
import '../firebase/vexda_firebase.dart';

const _logTag = '[VenueMarkerImageLoader:web]';
const _maxDownloadBytes = 5 * 1024 * 1024;

void _logFailure(String message, [Object? stackTrace]) {
  if (!kDebugMode) return;
  debugPrint('$_logTag $message');
  if (stackTrace != null) debugPrint('$stackTrace');
}

Future<Uint8List?> loadMarkerImageBytes(String url, int targetSize) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    _logFailure('failure empty url');
    return null;
  }

  final storagePath = parseFirebaseStoragePathFromDownloadUrl(trimmed);
  if (storagePath != null) {
    return _loadFromFirebaseStorage(storagePath);
  }

  return _loadViaHtmlCanvas(trimmed, targetSize);
}

Future<Uint8List?> _loadFromFirebaseStorage(String storagePath) async {
  if (!VexdaFirebase.isReady) {
    _logFailure('failure Firebase not initialized storagePath=$storagePath');
    return null;
  }

  try {
    final bytes = await FirebaseStorage.instance
        .ref(storagePath)
        .getData(_maxDownloadBytes);
    if (bytes == null || bytes.isEmpty) {
      _logFailure(
        'failure Firebase getData returned empty storagePath=$storagePath',
      );
      return null;
    }

    return bytes;
  } on FirebaseException catch (error, stackTrace) {
    _logFailure(
      'failure Firebase getData storagePath=$storagePath '
      'code=${error.code} plugin=${error.plugin} message=${error.message}',
      stackTrace,
    );
    return null;
  } catch (error, stackTrace) {
    _logFailure(
      'failure Firebase getData storagePath=$storagePath error=$error',
      stackTrace,
    );
    return null;
  }
}

Future<Uint8List?> _loadViaHtmlCanvas(String url, int targetSize) async {
  final image = await _loadHtmlImage(url);
  if (image == null) {
    _logFailure('failure html image onError or timeout url=$url');
    return null;
  }

  final canvas = web.HTMLCanvasElement()
    ..width = targetSize
    ..height = targetSize;
  final context = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
  if (context == null) {
    _logFailure('failure canvas 2d context unavailable url=$url');
    return null;
  }

  try {
    context.drawImage(image, 0, 0, targetSize, targetSize);
  } catch (error, stackTrace) {
    _logFailure('failure drawImage url=$url error=$error', stackTrace);
    return null;
  }

  final blob = await _canvasToPngBlob(canvas, url);
  if (blob == null) {
    _logFailure('failure canvas.toBlob url=$url');
    return null;
  }

  final bytes = await _blobToBytes(blob, url);
  if (bytes == null || bytes.isEmpty) {
    _logFailure('failure blob read returned empty url=$url');
    return null;
  }

  return bytes;
}

Future<web.HTMLImageElement?> _loadHtmlImage(String url) async {
  final completer = Completer<web.HTMLImageElement?>();
  final image = web.HTMLImageElement()
    ..crossOrigin = 'anonymous'
    ..src = url;

  image.onLoad.first.then((_) {
    if (!completer.isCompleted) completer.complete(image);
  });
  image.onError.first.then((_) {
    if (!completer.isCompleted) completer.complete(null);
  });

  return completer.future.timeout(
    const Duration(seconds: 8),
    onTimeout: () => null,
  );
}

Future<web.Blob?> _canvasToPngBlob(web.HTMLCanvasElement canvas, String url) {
  final completer = Completer<web.Blob?>();
  void complete(web.Blob? blob) {
    if (!completer.isCompleted) completer.complete(blob);
  }

  try {
    canvas.toBlob(complete.toJS, 'image/png');
  } catch (error, stackTrace) {
    _logFailure('failure canvas.toBlob threw url=$url error=$error', stackTrace);
    complete(null);
  }

  return completer.future.timeout(
    const Duration(seconds: 4),
    onTimeout: () => null,
  );
}

Future<Uint8List?> _blobToBytes(web.Blob blob, String url) async {
  try {
    final reader = web.FileReader();
    reader.readAsArrayBuffer(blob);

    await reader.onLoadEnd.first;
    final bytes = (reader.result as JSArrayBuffer?)?.toDart.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      _logFailure('failure FileReader empty result url=$url');
      return null;
    }
    return bytes;
  } catch (error, stackTrace) {
    _logFailure('failure FileReader url=$url error=$error', stackTrace);
    return null;
  }
}
