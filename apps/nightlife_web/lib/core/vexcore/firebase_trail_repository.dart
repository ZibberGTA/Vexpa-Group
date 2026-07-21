import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/trails/trails.dart';

import 'web_trail_document_mapper.dart';

/// Read-only Firebase adapter for trail discovery in venue management.
final class FirebaseTrailRepository implements TrailRepository {
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
      final snapshot = WebTrailDocumentMapper.parseTrailDocument(
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
    return _collection
        .doc(trailId.trim())
        .snapshots()
        .map((doc) {
          if (!doc.exists) return const DataSuccess<TrailSnapshot?>(null);
          return DataSuccess(
            WebTrailDocumentMapper.parseTrailDocument(doc.id, doc.data()),
          );
        })
        .transform(
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
    return _collection
        .limit(query.limit)
        .snapshots()
        .map((snapshot) {
          return DataSuccess(_mapAndFilter(snapshot.docs, query));
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.add(_failure('watchList', error, stackTrace));
            },
          ),
        );
  }

  List<TrailSnapshot> _mapAndFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    TrailListQuery query,
  ) {
    final mapped = <TrailSnapshot>[];
    for (final doc in docs) {
      final snapshot = WebTrailDocumentMapper.parseTrailDocument(
        doc.id,
        doc.data(),
      );
      if (snapshot == null) continue;
      if (query.publishedOnly && !snapshot.published) continue;
      if (!query.includeArchived &&
          snapshot.status is KnownTrailStatusSnapshot &&
          (snapshot.status as KnownTrailStatusSnapshot).value ==
              TrailStatusValue.archived) {
        continue;
      }
      if (query.trailIds.isNotEmpty &&
          !query.trailIds.contains(snapshot.trailId)) {
        continue;
      }
      mapped.add(snapshot);
    }
    return mapped;
  }

  DataFailure<T> _failure<T>(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    return DataFailure(
      VexException(
        'Trail $operation failed: $error',
        code: 'trail-$operation-failed',
        cause: error,
      ),
    );
  }

  @override
  Future<DataResult<TrailSnapshot>> archive(ArchiveTrailCommand command) =>
      _unsupported('archive');

  @override
  Future<DataResult<TrailSnapshot>> create(CreateTrailCommand command) =>
      _unsupported('create');

  @override
  Future<DataResult<void>> delete(DeleteTrailCommand command) =>
      _unsupported('delete');

  @override
  Future<DataResult<TrailSnapshot>> duplicate(DuplicateTrailCommand command) =>
      _unsupported('duplicate');

  @override
  Future<DataResult<TrailSnapshot>> publish(PublishTrailCommand command) =>
      _unsupported('publish');

  @override
  Future<DataResult<TrailSnapshot>> replaceDocument(
    ReplaceTrailDocumentCommand command,
  ) => _unsupported('replaceDocument');

  @override
  Future<DataResult<TrailSnapshot>> unpublish(UnpublishTrailCommand command) =>
      _unsupported('unpublish');

  @override
  Future<DataResult<TrailSnapshot>> updateMetadata(
    UpdateTrailMetadataCommand command,
  ) => _unsupported('updateMetadata');

  @override
  Future<DataResult<TrailSnapshot>> updateStops(
    UpdateTrailStopsCommand command,
  ) => _unsupported('updateStops');

  Future<DataResult<T>> _unsupported<T>(String operation) {
    return Future.value(
      DataFailure(
        VexException(
          'Trail $operation is not supported in web read adapter.',
          code: 'trail-write-unsupported',
        ),
      ),
    );
  }
}
