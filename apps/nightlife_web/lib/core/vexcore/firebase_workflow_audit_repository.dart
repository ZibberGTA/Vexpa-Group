import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vex_core/data/data_result.dart';
import 'package:vex_core/shared/vex_exception.dart';
import 'package:vex_core/workflow/workflow.dart';

import 'firebase_workflow_document_mapper.dart';

/// Firebase adapter for VexCore [WorkflowAuditRepository].
final class FirebaseWorkflowAuditRepository implements WorkflowAuditRepository {
  FirebaseWorkflowAuditRepository({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? (_firestore ??= FirebaseFirestore.instance);

  @override
  Future<DataResult<List<WorkflowAuditEntrySnapshot>>> list(
    String requestId,
  ) async {
    try {
      final snapshot = await _auditCollection(
        requestId,
      ).orderBy('createdAt').get();
      return DataSuccess(_mapDocs(snapshot.docs));
    } on Object catch (error, stackTrace) {
      return _failure('list', error, stackTrace);
    }
  }

  @override
  Stream<DataResult<List<WorkflowAuditEntrySnapshot>>> watch(String requestId) {
    return _auditCollection(requestId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => DataSuccess(_mapDocs(snapshot.docs)))
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.add(_failure('watch', error, stackTrace));
            },
          ),
        );
  }

  CollectionReference<Map<String, dynamic>> _auditCollection(String requestId) {
    return _db
        .collection(WorkflowPaths.workflowRequestsCollection)
        .doc(requestId.trim())
        .collection('audit');
  }

  List<WorkflowAuditEntrySnapshot> _mapDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return [
      for (final doc in docs)
        if (FirebaseWorkflowDocumentMapper.parseAuditDocument(
              doc.id,
              doc.data(),
            )
            case final snapshot?)
          snapshot,
    ];
  }

  DataFailure<T> _failure<T>(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    return DataFailure(
      VexException(
        'Workflow audit $operation failed: $error',
        code: 'workflow-audit-$operation-failed',
        cause: error,
      ),
    );
  }
}
