/// Actor performing a workflow command or audit entry.
enum WorkflowActorKind { submitter, reviewer, system, admin }

extension WorkflowActorKindCodec on WorkflowActorKind {
  String get persistenceValue => switch (this) {
    WorkflowActorKind.submitter => 'submitter',
    WorkflowActorKind.reviewer => 'reviewer',
    WorkflowActorKind.system => 'system',
    WorkflowActorKind.admin => 'admin',
  };
}

final class WorkflowActor {
  const WorkflowActor({required this.uid, required this.kind});

  final String uid;
  final WorkflowActorKind kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowActor && other.uid == uid && other.kind == kind;

  @override
  int get hashCode => Object.hash(uid, kind);
}
