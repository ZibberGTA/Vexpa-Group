import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/trails/trails.dart';

import 'mobile_trail_document_mapper.dart';

/// Firebase adapter for VexCore [TrailRepository].
class FirebaseTrailRepository implements TrailRepository {
  FirebaseTrailRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? (_firestore ??= FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(TrailPaths.trailsCollection);

  @override
  Future<DataResult<TrailSnapshot>> get(String trailId) async {
    try {
      final doc = await _collection.doc(trailId.trim()).get();
      if (!doc.exists) {
        return DataFailure(
          VexException('Trail not found.', code: 'trail-not-found'),
        );
      }
      final snapshot = MobileTrailDocumentMapper.parseTrailDocument(
        doc.id,
        doc.data(),
      );
      if (snapshot == null) {
        return DataFailure(
          VexException('Trail mapping failed.', code: 'trail-map-failed'),
        );
      }
      return DataSuccess(snapshot);
    } on Object catch (error, stackTrace) {
      return _failure('get', error, stackTrace);
    }
  }

  @override
  Stream<DataResult<TrailSnapshot?>> watch(String trailId) {
    return _collection.doc(trailId.trim()).snapshots().map((doc) {
      if (!doc.exists) return const DataSuccess<TrailSnapshot?>(null);
      return DataSuccess(
        MobileTrailDocumentMapper.parseTrailDocument(doc.id, doc.data()),
      );
    }).transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) {
          sink.add(_failure('watch', error, stackTrace));
        },
      ),
    );
  }

  @override
  Future<DataResult<List<TrailSnapshot>>> list(TrailListQuery query) async {
    try {
      final snapshot = await _collection.limit(query.limit).get();
      return DataSuccess(_mapAndFilter(snapshot.docs, query));
    } on Object catch (error, stackTrace) {
      return _failure('list', error, stackTrace);
    }
  }

  @override
  Stream<DataResult<List<TrailSnapshot>>> watchList(TrailListQuery query) {
    return _collection.snapshots().map((snapshot) {
      return DataSuccess(_mapAndFilter(snapshot.docs, query));
    }).transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) {
          sink.add(_failure('watchList', error, stackTrace));
        },
      ),
    );
  }

  @override
  Future<DataResult<TrailSnapshot>> create(CreateTrailCommand command) async {
    try {
      final ref = command.trailId == null
          ? _collection.doc()
          : _collection.doc(command.trailId!.trim());
      final durationMinutes =
          command.availabilityEnd.difference(command.availabilityStart).inMinutes;
      final name = command.name.trim().isEmpty
          ? 'Untitled Trail'
          : command.name.trim();
      final description = command.description.trim();

      final payload = {
        'name': name,
        'title': name,
        'description': description,
        'subtitle': description,
        'bannerImageUrl': command.bannerImageUrl.trim(),
        'status': TrailStatusValue.draft.firestoreValue,
        'published': false,
        'area': command.area.trim(),
        'availabilityStart': Timestamp.fromDate(command.availabilityStart),
        'availabilityEnd': Timestamp.fromDate(command.availabilityEnd),
        'startTime': Timestamp.fromDate(command.availabilityStart),
        'endTime': Timestamp.fromDate(command.availabilityEnd),
        'estimatedDurationMinutes': durationMinutes,
        'estimatedWalkingDistance': 0,
        'averageRating': 0,
        'venueCount': 0,
        'trailType': command.trailType.firestoreValue,
        'publishedAt': null,
        'generatedAt': FieldValue.serverTimestamp(),
        'stops': const <Map<String, Object?>>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await ref.set(payload);
      return get(ref.id);
    } on Object catch (error, stackTrace) {
      return _failure('create', error, stackTrace);
    }
  }

  @override
  Future<DataResult<TrailSnapshot>> updateMetadata(
    UpdateTrailMetadataCommand command,
  ) async {
    try {
      final name = command.name.trim().isEmpty
          ? 'Untitled Trail'
          : command.name.trim();
      final description = command.description.trim();
      await _collection.doc(command.trailId.trim()).set(
        {
          'name': name,
          'title': name,
          'description': description,
          'subtitle': description,
          'bannerImageUrl': command.bannerImageUrl.trim(),
          'area': command.area.trim(),
          'availabilityStart': Timestamp.fromDate(command.availabilityStart),
          'availabilityEnd': Timestamp.fromDate(command.availabilityEnd),
          'startTime': Timestamp.fromDate(command.availabilityStart),
          'endTime': Timestamp.fromDate(command.availabilityEnd),
          'estimatedDurationMinutes': command.availabilityEnd
              .difference(command.availabilityStart)
              .inMinutes,
          'trailType': command.trailType.firestoreValue,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return get(command.trailId);
    } on Object catch (error, stackTrace) {
      return _failure('updateMetadata', error, stackTrace);
    }
  }

  @override
  Future<DataResult<TrailSnapshot>> updateStops(
    UpdateTrailStopsCommand command,
  ) async {
    try {
      await _collection.doc(command.trailId.trim()).set(
        {
          'stops': MobileTrailDocumentMapper.stopsToFirestore(command.stops),
          'venueCount': command.venueCount,
          'availabilityStart': Timestamp.fromDate(command.availabilityStart),
          'availabilityEnd': Timestamp.fromDate(command.availabilityEnd),
          'estimatedDurationMinutes': command.estimatedDurationMinutes,
          'startTime': Timestamp.fromDate(command.availabilityStart),
          'endTime': Timestamp.fromDate(command.availabilityEnd),
          'status': TrailStatusValue.draft.firestoreValue,
          'published': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return get(command.trailId);
    } on Object catch (error, stackTrace) {
      return _failure('updateStops', error, stackTrace);
    }
  }

  @override
  Future<DataResult<TrailSnapshot>> replaceDocument(
    ReplaceTrailDocumentCommand command,
  ) async {
    try {
      final snapshot = command.snapshot;
      await _collection.doc(command.trailId.trim()).set(
        {
          'name': snapshot.name,
          'title': snapshot.title,
          'description': snapshot.description,
          'subtitle': snapshot.subtitle,
          'bannerImageUrl': snapshot.bannerImageUrl.trim(),
          'status': _statusValue(snapshot.status),
          'published': snapshot.published,
          'area': snapshot.area.trim(),
          'availabilityStart': Timestamp.fromDate(snapshot.availabilityStart),
          'availabilityEnd': Timestamp.fromDate(snapshot.availabilityEnd),
          'startTime': Timestamp.fromDate(snapshot.startTime),
          'endTime': Timestamp.fromDate(snapshot.endTime),
          'estimatedDurationMinutes': snapshot.estimatedDurationMinutes,
          'estimatedWalkingDistance': snapshot.estimatedWalkingDistance,
          'averageRating': snapshot.averageRating,
          'venueCount': snapshot.venueCount,
          'trailType': _typeValue(snapshot.trailType),
          'generatedAt': Timestamp.fromDate(snapshot.generatedAt),
          'stops': MobileTrailDocumentMapper.stopsToFirestore(snapshot.stops),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: false),
      );
      return get(command.trailId);
    } on Object catch (error, stackTrace) {
      return _failure('replaceDocument', error, stackTrace);
    }
  }

  @override
  Future<DataResult<TrailSnapshot>> publish(PublishTrailCommand command) async {
    try {
      await _collection.doc(command.trailId.trim()).update({
        'status': TrailStatusValue.published.firestoreValue,
        'published': true,
        'publishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return get(command.trailId);
    } on Object catch (error, stackTrace) {
      return _failure('publish', error, stackTrace);
    }
  }

  @override
  Future<DataResult<TrailSnapshot>> unpublish(
    UnpublishTrailCommand command,
  ) async {
    try {
      await _collection.doc(command.trailId.trim()).set(
        {
          'status': TrailStatusValue.draft.firestoreValue,
          'published': false,
          'unpublishedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return get(command.trailId);
    } on Object catch (error, stackTrace) {
      return _failure('unpublish', error, stackTrace);
    }
  }

  @override
  Future<DataResult<TrailSnapshot>> archive(ArchiveTrailCommand command) async {
    try {
      await _collection.doc(command.trailId.trim()).set(
        {
          'status': TrailStatusValue.archived.firestoreValue,
          'published': false,
          'archivedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return get(command.trailId);
    } on Object catch (error, stackTrace) {
      return _failure('archive', error, stackTrace);
    }
  }

  @override
  Future<DataResult<TrailSnapshot>> duplicate(
    DuplicateTrailCommand command,
  ) async {
    try {
      final source = await get(command.sourceTrailId);
      if (source case DataFailure()) {
        return source;
      }
      final sourceSnapshot = (source as DataSuccess<TrailSnapshot>).value;
      final ref = command.newTrailId == null
          ? _collection.doc()
          : _collection.doc(command.newTrailId!.trim());

      final data = {
        'name': '${sourceSnapshot.name} Copy',
        'title': '${sourceSnapshot.name} Copy',
        'description': sourceSnapshot.description,
        'subtitle': sourceSnapshot.subtitle,
        'bannerImageUrl': sourceSnapshot.bannerImageUrl,
        'status': TrailStatusValue.draft.firestoreValue,
        'published': false,
        'area': sourceSnapshot.area,
        'availabilityStart':
            Timestamp.fromDate(sourceSnapshot.availabilityStart),
        'availabilityEnd': Timestamp.fromDate(sourceSnapshot.availabilityEnd),
        'startTime': Timestamp.fromDate(sourceSnapshot.startTime),
        'endTime': Timestamp.fromDate(sourceSnapshot.endTime),
        'estimatedDurationMinutes': sourceSnapshot.estimatedDurationMinutes,
        'estimatedWalkingDistance': sourceSnapshot.estimatedWalkingDistance,
        'averageRating': sourceSnapshot.averageRating,
        'venueCount': sourceSnapshot.venueCount,
        'trailType': _typeValue(sourceSnapshot.trailType),
        'generatedAt': FieldValue.serverTimestamp(),
        'stops': MobileTrailDocumentMapper.stopsToFirestore(sourceSnapshot.stops),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await ref.set(data);
      return get(ref.id);
    } on Object catch (error, stackTrace) {
      return _failure('duplicate', error, stackTrace);
    }
  }

  @override
  Future<DataResult<void>> delete(DeleteTrailCommand command) async {
    try {
      await _collection.doc(command.trailId.trim()).delete();
      return const DataSuccess(null);
    } on Object catch (error, stackTrace) {
      return _failure('delete', error, stackTrace);
    }
  }

  List<TrailSnapshot> _mapAndFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    TrailListQuery query,
  ) {
    final trails = docs
        .map(
          (doc) => MobileTrailDocumentMapper.parseTrailDocument(
            doc.id,
            doc.data(),
          ),
        )
        .whereType<TrailSnapshot>()
        .where((trail) {
          if (query.trailIds.isNotEmpty &&
              !query.trailIds.contains(trail.trailId)) {
            return false;
          }
          if (query.publishedOnly && !trail.published) return false;
          if (!query.includeArchived &&
              trail.status is KnownTrailStatusSnapshot &&
              (trail.status as KnownTrailStatusSnapshot).value ==
                  TrailStatusValue.archived) {
            return false;
          }
          if (query.statuses.isNotEmpty) {
            final status = _statusValue(trail.status);
            if (!query.statuses.contains(status)) return false;
          }
          return true;
        })
        .toList();

    trails.sort((a, b) {
      if (query.sort == TrailListSort.discoveryDefault) {
        final typeCompare = _typeSortIndex(trailType: a.trailType)
            .compareTo(_typeSortIndex(trailType: b.trailType));
        if (typeCompare != 0) return typeCompare;
        return b.averageRating.compareTo(a.averageRating);
      }
      return b.generatedAt.compareTo(a.generatedAt);
    });

    if (trails.length > query.limit) {
      return trails.take(query.limit).toList();
    }
    return trails;
  }

  static int _typeSortIndex({required TrailTypeSnapshot trailType}) {
    return switch (trailType) {
      KnownTrailTypeSnapshot(:final value) =>
        value == TrailTypeValue.curated ? 0 : 1,
      _ => 1,
    };
  }

  static String _statusValue(TrailStatusSnapshot status) {
    return switch (status) {
      KnownTrailStatusSnapshot(:final value) => value.firestoreValue,
      UnknownTrailStatusSnapshot(:final rawValue) => rawValue,
      MissingTrailStatusSnapshot() => TrailStatusValue.draft.firestoreValue,
    };
  }

  static String _typeValue(TrailTypeSnapshot type) {
    return switch (type) {
      KnownTrailTypeSnapshot(:final value) => value.firestoreValue,
      UnknownTrailTypeSnapshot(:final rawValue) => rawValue,
      MissingTrailTypeSnapshot() => TrailTypeValue.curated.firestoreValue,
    };
  }

  DataFailure<T> _failure<T>(String label, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[FirebaseTrailRepository] $label failed: $error');
    }
    return DataFailure(
      VexException(
        'Trail repository $label failed.',
        code: error is FirebaseException ? error.code : 'trail-$label-failed',
        cause: error,
      ),
    );
  }
}
