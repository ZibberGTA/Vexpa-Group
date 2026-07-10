import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/features/venue_management/data/venue_media_upload_errors.dart';

void main() {
  group('VenueMediaUploadException', () {
    test('maps storage permission denied', () {
      final error = VenueMediaUploadException.fromFirebase(
        FirebaseException(
          plugin: 'firebase_storage',
          code: 'unauthorized',
          message: 'User is not authorized',
        ),
        context: 'storagePath=venues/v1/media/gallery/a.jpg',
      );

      expect(error.kind, VenueMediaUploadFailureKind.storagePermissionDenied);
      expect(error.userMessage, contains('Storage permission denied'));
      expect(error.devDetails, contains('venues/v1/media/gallery/a.jpg'));
    });

    test('maps firestore permission denied', () {
      final error = VenueMediaUploadException.fromFirebase(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
        context: 'firestorePath=venues/v1/media/a',
      );

      expect(error.kind, VenueMediaUploadFailureKind.firestorePermissionDenied);
      expect(error.userMessage, contains('Firestore permission denied'));
    });

    test('messageForUi includes dev details only when requested', () {
      final error = VenueMediaUploadException(
        kind: VenueMediaUploadFailureKind.fileTooLarge,
        userMessage: 'File too large.',
        devDetails: 'sizeBytes=99999999',
      );

      expect(error.messageForUi(includeDevDetails: false), 'File too large.');
      expect(
        error.messageForUi(includeDevDetails: true),
        contains('sizeBytes=99999999'),
      );
    });
  });
}
