import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/trails/trails.dart';

import 'mobile_trail_document_mapper.dart';

/// Firebase adapter for VexCore [TrailActivityRepository].
class FirebaseTrailActivityRepository implements TrailActivityRepository {
  FirebaseTrailActivityRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? (_firestore ??= FirebaseFirestore.instance);

  @override
  Future<DataResult<TrailActivitySnapshot>> append(
    AppendTrailActivityCommand command,
  ) async {
    try {
      final ref = await _db.collection(TrailPaths.trailActivityCollection).add({
        'trailId': command.trailId,
        'userId': command.userId,
        'isAnonymous': command.isAnonymous,
        'action': command.action,
        'venueId': command.venueId,
        'stopOrder': command.stopOrder,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return DataSuccess(
        TrailActivitySnapshot(
          activityId: ref.id,
          trailId: command.trailId,
          userId: command.userId,
          isAnonymous: command.isAnonymous,
          action: command.action,
          createdAt: DateTime.now(),
          venueId: command.venueId,
          stopOrder: command.stopOrder,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[FirebaseTrailActivityRepository] append failed: $error');
      }
      return DataFailure(
        VexException(
          'Failed to append trail activity.',
          code: error is FirebaseException ? error.code : 'activity-append-failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<DataResult<List<TrailActivitySnapshot>>> list(
    TrailActivityListQuery query,
  ) async {
    try {
      Query<Map<String, dynamic>> firestoreQuery =
          _db.collection(TrailPaths.trailActivityCollection);
      if (query.trailId != null) {
        firestoreQuery = firestoreQuery.where(
          'trailId',
          isEqualTo: query.trailId,
        );
      }
      if (query.userId != null) {
        firestoreQuery = firestoreQuery.where(
          'userId',
          isEqualTo: query.userId,
        );
      }
      final snapshot = await firestoreQuery.limit(query.limit).get();
      final items = snapshot.docs
          .map(
            (doc) => MobileTrailDocumentMapper.parseActivityDocument(
              doc.id,
              doc.data(),
            ),
          )
          .whereType<TrailActivitySnapshot>()
          .toList();
      return DataSuccess(items);
    } on Object catch (error, stackTrace) {
      return DataFailure(
        VexException(
          'Failed to list trail activity.',
          code: error is FirebaseException ? error.code : 'activity-list-failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<DataResult<List<TrailActivitySnapshot>>> watchList(
    TrailActivityListQuery query,
  ) {
    Query<Map<String, dynamic>> firestoreQuery =
        _db.collection(TrailPaths.trailActivityCollection);
    if (query.trailId != null) {
      firestoreQuery = firestoreQuery.where(
        'trailId',
        isEqualTo: query.trailId,
      );
    }
    return firestoreQuery.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(
            (doc) => MobileTrailDocumentMapper.parseActivityDocument(
              doc.id,
              doc.data(),
            ),
          )
          .whereType<TrailActivitySnapshot>()
          .toList();
      return DataSuccess(items);
    });
  }
}
