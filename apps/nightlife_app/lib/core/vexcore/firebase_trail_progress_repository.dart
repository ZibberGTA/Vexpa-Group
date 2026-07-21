import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/trails/trails.dart';

import 'mobile_trail_document_mapper.dart';

/// Firebase adapter for VexCore [TrailProgressRepository].
class FirebaseTrailProgressRepository implements TrailProgressRepository {
  FirebaseTrailProgressRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? (_firestore ??= FirebaseFirestore.instance);

  DocumentReference<Map<String, dynamic>> _progressRef(
    String userId,
    String trailId,
  ) {
    return _db.doc(TrailPaths.userTrailProgressDocument(userId, trailId));
  }

  DocumentReference<Map<String, dynamic>> _activeStateRef(String userId) {
    return _db.doc(TrailPaths.userActiveTrailStateDocument(userId));
  }

  DocumentReference<Map<String, dynamic>> _legacyProgressRef(String userId) {
    return _db.doc(TrailPaths.legacyUserTrailProgressDocument(userId));
  }

  @override
  Future<DataResult<TrailProgressSnapshot>> get({
    required String userId,
    required String trailId,
  }) async {
    try {
      final doc = await _progressRef(userId, trailId).get();
      if (!doc.exists) {
        if (trailId == TrailPaths.activeTrailDocumentId) {
          final legacy = await getLegacyMirror(userId: userId);
          if (legacy case DataSuccess(value: final progress?) when progress != null) {
            return DataSuccess(progress);
          }
        }
        return DataFailure(
          VexException('Trail progress not found.', code: 'progress-not-found'),
        );
      }
      final snapshot = MobileTrailDocumentMapper.parseProgressDocument(doc.data());
      if (snapshot == null) {
        return DataFailure(
          VexException('Progress mapping failed.', code: 'progress-map-failed'),
        );
      }
      return DataSuccess(snapshot);
    } on Object catch (error, stackTrace) {
      return _failure('get', error, stackTrace);
    }
  }

  @override
  Stream<DataResult<TrailProgressSnapshot?>> watch({
    required String userId,
    required String trailId,
  }) {
    return _progressRef(userId, trailId).snapshots().asyncMap((doc) async {
      if (doc.exists) {
        return DataSuccess(
          MobileTrailDocumentMapper.parseProgressDocument(doc.data()),
        );
      }
      if (trailId != TrailPaths.activeTrailDocumentId) {
        return const DataSuccess<TrailProgressSnapshot?>(null);
      }
      final legacy = await getLegacyMirror(userId: userId);
      return switch (legacy) {
        DataSuccess(value: final progress) => DataSuccess(progress),
        DataFailure() => legacy as DataResult<TrailProgressSnapshot?>,
      };
    }).transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) {
          sink.add(_failure('watch', error, stackTrace));
        },
      ),
    );
  }

  @override
  Future<DataResult<TrailProgressSnapshot?>> getLegacyMirror({
    required String userId,
  }) async {
    try {
      final doc = await _legacyProgressRef(userId).get();
      if (!doc.exists) return const DataSuccess(null);
      return DataSuccess(
        MobileTrailDocumentMapper.parseProgressDocument(doc.data()),
      );
    } on Object catch (error, stackTrace) {
      return _failure('getLegacyMirror', error, stackTrace);
    }
  }

  @override
  Future<DataResult<List<TrailProgressSnapshot>>> list(
    TrailProgressListQuery query,
  ) async {
    return const DataSuccess([]);
  }

  @override
  Future<DataResult<TrailActiveStateSnapshot?>> getActiveState({
    required String userId,
  }) async {
    try {
      final doc = await _activeStateRef(userId).get();
      if (!doc.exists) return const DataSuccess(null);
      return DataSuccess(
        MobileTrailDocumentMapper.parseActiveState(doc.data()),
      );
    } on Object catch (error, stackTrace) {
      return _failure('getActiveState', error, stackTrace);
    }
  }

  @override
  Stream<DataResult<TrailActiveStateSnapshot?>> watchActiveState({
    required String userId,
  }) {
    return _activeStateRef(userId).snapshots().map((doc) {
      if (!doc.exists) return const DataSuccess<TrailActiveStateSnapshot?>(null);
      return DataSuccess(
        MobileTrailDocumentMapper.parseActiveState(doc.data()),
      );
    }).transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) {
          sink.add(_failure('watchActiveState', error, stackTrace));
        },
      ),
    );
  }

  @override
  Future<DataResult<void>> setActiveTrail(SetActiveTrailCommand command) async {
    try {
      await _activeStateRef(command.userId).set(
        {
          'activeTrailId': command.activeTrailId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return const DataSuccess(null);
    } on Object catch (error, stackTrace) {
      return _failure('setActiveTrail', error, stackTrace);
    }
  }

  @override
  Future<DataResult<TrailProgressSnapshot>> createProgress(
    CreateTrailProgressCommand command,
  ) async {
    try {
      final snapshot = _snapshotFromCreate(command);
      final batch = _db.batch();
      batch.set(
        _activeStateRef(command.userId),
        {
          'activeTrailId': command.trailId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        _progressRef(command.userId, command.trailId),
        _joinPayload(snapshot),
        SetOptions(merge: false),
      );
      if (command.mirrorLegacyProgress) {
        batch.set(
          _legacyProgressRef(command.userId),
          _joinPayload(snapshot),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      return get(userId: command.userId, trailId: command.trailId);
    } on Object catch (error, stackTrace) {
      return _failure('createProgress', error, stackTrace);
    }
  }

  @override
  Future<DataResult<TrailProgressSnapshot>> checkIn(
    CheckInTrailProgressCommand command,
  ) async {
    return _writeProgressUpdate(
      userId: command.userId,
      trailId: command.trailId,
      snapshot: _snapshotFromCheckIn(command),
      mirrorLegacyProgress: command.mirrorLegacyProgress,
      checkedInStopOrderToUnion: command.checkedInStopOrder,
      updateActiveState: true,
    );
  }

  @override
  Future<DataResult<TrailProgressSnapshot>> continueProgress(
    ContinueTrailProgressCommand command,
  ) async {
    return _writeProgressUpdate(
      userId: command.userId,
      trailId: command.trailId,
      snapshot: _snapshotFromContinue(command),
      mirrorLegacyProgress: command.mirrorLegacyProgress,
    );
  }

  @override
  Future<DataResult<TrailProgressSnapshot>> skipStop(
    SkipTrailProgressCommand command,
  ) async {
    return _writeProgressUpdate(
      userId: command.userId,
      trailId: command.trailId,
      snapshot: _snapshotFromSkip(command),
      mirrorLegacyProgress: command.mirrorLegacyProgress,
    );
  }

  @override
  Future<DataResult<void>> mirrorLegacyProgress(
    MirrorLegacyTrailProgressCommand command,
  ) async {
    try {
      await _legacyProgressRef(command.userId).set(
        MobileTrailDocumentMapper.progressSnapshotToFirestore(command.progress),
        SetOptions(merge: true),
      );
      return const DataSuccess(null);
    } on Object catch (error, stackTrace) {
      return _failure('mirrorLegacyProgress', error, stackTrace);
    }
  }

  Future<DataResult<TrailProgressSnapshot>> _writeProgressUpdate({
    required String userId,
    required String trailId,
    required TrailProgressSnapshot snapshot,
    required bool mirrorLegacyProgress,
    int? checkedInStopOrderToUnion,
    bool updateActiveState = false,
  }) async {
    try {
      final payload = MobileTrailDocumentMapper.progressSnapshotToFirestore(
        snapshot,
        includeCheckedInArrayUnion: checkedInStopOrderToUnion != null,
        checkedInStopOrderToUnion: checkedInStopOrderToUnion,
      );
      if (checkedInStopOrderToUnion == null) {
        payload.remove('checkedInStops');
      }
      payload['updatedAt'] = FieldValue.serverTimestamp();
      if (snapshot.completed) {
        payload['completedAt'] = FieldValue.serverTimestamp();
      }

      final batch = _db.batch();
      if (updateActiveState) {
        batch.set(
          _activeStateRef(userId),
          {
            'activeTrailId': trailId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      batch.set(
        _progressRef(userId, trailId),
        payload,
        SetOptions(merge: true),
      );
      if (mirrorLegacyProgress) {
        batch.set(
          _legacyProgressRef(userId),
          payload,
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      return get(userId: userId, trailId: trailId);
    } on Object catch (error, stackTrace) {
      return _failure('writeProgressUpdate', error, stackTrace);
    }
  }

  Map<String, Object?> _joinPayload(TrailProgressSnapshot snapshot) {
    return {
      'trailId': snapshot.trailId,
      'trailGeneratedAt': snapshot.trailGeneratedAt == null
          ? null
          : Timestamp.fromDate(snapshot.trailGeneratedAt!),
      'started': snapshot.started,
      'completed': snapshot.completed,
      'currentStop': snapshot.currentStop,
      'checkedInStops': snapshot.checkedInStops.toList(),
      'stopStates': MobileTrailDocumentMapper.stopStatesToFirestore(
        snapshot.stopStates,
      ),
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TrailProgressSnapshot _snapshotFromCreate(CreateTrailProgressCommand command) {
    return TrailProgressSnapshot(
      trailId: command.trailId,
      started: true,
      completed: false,
      currentStop: 0,
      checkedInStops: const {},
      stopStates: command.stopStates,
      trailGeneratedAt: command.trailGeneratedAt,
    );
  }

  TrailProgressSnapshot _snapshotFromCheckIn(
    CheckInTrailProgressCommand command,
  ) {
    return TrailProgressSnapshot(
      trailId: command.trailId,
      started: true,
      completed: command.completed,
      currentStop: command.currentStop,
      checkedInStops: {command.checkedInStopOrder},
      stopStates: command.stopStates,
      trailGeneratedAt: command.trailGeneratedAt,
      lastCheckedInVenueId: command.lastCheckedInVenueId,
      lastCheckedInStopOrder: command.lastCheckedInStopOrder,
    );
  }

  TrailProgressSnapshot _snapshotFromContinue(
    ContinueTrailProgressCommand command,
  ) {
    return TrailProgressSnapshot(
      trailId: command.trailId,
      started: true,
      completed: command.completed,
      currentStop: command.currentStop,
      checkedInStops: const {},
      stopStates: command.stopStates,
      trailGeneratedAt: command.trailGeneratedAt,
    );
  }

  TrailProgressSnapshot _snapshotFromSkip(SkipTrailProgressCommand command) {
    return TrailProgressSnapshot(
      trailId: command.trailId,
      started: true,
      completed: command.completed,
      currentStop: command.currentStop,
      checkedInStops: const {},
      stopStates: command.stopStates,
      trailGeneratedAt: command.trailGeneratedAt,
    );
  }

  DataFailure<T> _failure<T>(String label, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[FirebaseTrailProgressRepository] $label failed: $error');
    }
    return DataFailure(
      VexException(
        'Trail progress repository $label failed.',
        code: error is FirebaseException ? error.code : 'progress-$label-failed',
        cause: error,
      ),
    );
  }
}
