import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Typed upload failures with user-facing and developer detail messages.
enum VenueMediaUploadFailureKind {
  noActiveVenue,
  unsupportedFileType,
  fileTooLarge,
  uploadLimitExceeded,
  storagePermissionDenied,
  firestorePermissionDenied,
  missingDownloadUrl,
  metadataWriteFailed,
  storageUnavailable,
  firestoreUnavailable,
  notSignedIn,
  accessDenied,
  unknown,
}

class VenueMediaUploadException implements Exception {
  VenueMediaUploadException({
    required this.kind,
    required this.userMessage,
    required this.devDetails,
    this.cause,
    this.stackTrace,
  });

  final VenueMediaUploadFailureKind kind;
  final String userMessage;
  final String devDetails;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$userMessage ($kind)';

  String messageForUi({required bool includeDevDetails}) {
    if (!includeDevDetails) return userMessage;
    return '$userMessage\n\n$devDetails';
  }

  static VenueMediaUploadException fromObject(
    Object error, {
    StackTrace? stackTrace,
    String context = '',
  }) {
    if (error is VenueMediaUploadException) return error;

    if (error is FirebaseException) {
      return fromFirebase(error, stackTrace: stackTrace, context: context);
    }

    if (error is StateError) {
      final message = error.message;
      if (message.contains('Storage is not available')) {
        return VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.storageUnavailable,
          userMessage: 'Firebase Storage is not available. Reload the page and try again.',
          devDetails: _withContext(context, message),
          cause: error,
          stackTrace: stackTrace,
        );
      }
      if (message.contains('Firestore is not available')) {
        return VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.firestoreUnavailable,
          userMessage: 'Firestore is not available. Reload the page and try again.',
          devDetails: _withContext(context, message),
          cause: error,
          stackTrace: stackTrace,
        );
      }
    }

    return VenueMediaUploadException(
      kind: VenueMediaUploadFailureKind.unknown,
      userMessage: 'Could not upload images. Please try again.',
      devDetails: _withContext(context, error.toString()),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static VenueMediaUploadException fromFirebase(
    FirebaseException error, {
    StackTrace? stackTrace,
    String context = '',
  }) {
    final code = error.code;
    final plugin = error.plugin;
    final details = _withContext(
      context,
      'plugin=$plugin code=$code message=${error.message}',
    );

    if (plugin == 'firebase_storage') {
      if (code == 'unauthorized' || code == 'permission-denied') {
        return VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.storagePermissionDenied,
          userMessage:
              'Storage permission denied. Deploy storage.rules and confirm you manage this venue.',
          devDetails: details,
          cause: error,
          stackTrace: stackTrace,
        );
      }
      if (code == 'unauthenticated') {
        return VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.notSignedIn,
          userMessage: 'You must be signed in to upload media.',
          devDetails: details,
          cause: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (plugin == 'cloud_firestore') {
      if (code == 'permission-denied') {
        return VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.firestorePermissionDenied,
          userMessage:
              'Firestore permission denied creating media metadata for this venue.',
          devDetails: details,
          cause: error,
          stackTrace: stackTrace,
        );
      }
      if (code == 'unauthenticated') {
        return VenueMediaUploadException(
          kind: VenueMediaUploadFailureKind.notSignedIn,
          userMessage: 'You must be signed in to upload media.',
          devDetails: details,
          cause: error,
          stackTrace: stackTrace,
        );
      }
    }

    return VenueMediaUploadException(
      kind: VenueMediaUploadFailureKind.unknown,
      userMessage: 'Upload failed: ${error.message ?? code}.',
      devDetails: details,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static String _withContext(String context, String message) {
    if (context.trim().isEmpty) return message;
    return '$context\n$message';
  }
}
