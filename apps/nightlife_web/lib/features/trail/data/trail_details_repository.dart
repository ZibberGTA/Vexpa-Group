import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/vexda_firebase.dart';
import '../models/trail_details_view.dart';

/// Loads trail documents from Firestore for the trail details page.
class TrailDetailsRepository {
  TrailDetailsRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore? _resolveFirestore() {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (!VexdaFirebase.isReady) return null;
    return FirebaseFirestore.instance;
  }

  Future<TrailDetailsView?> loadTrail(String trailId) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return null;

    final doc = await firestore.collection('trails').doc(trailId.trim()).get();
    if (!doc.exists) return null;
    return TrailDetailsView.fromDoc(doc);
  }

  Future<List<TrailDetailsView>> loadRelatedTrails(String trailId) async {
    final firestore = _resolveFirestore();
    if (firestore == null) return const [];

    final snapshot = await firestore
        .collection('trails')
        .where('published', isEqualTo: true)
        .limit(8)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != trailId)
        .map(TrailDetailsView.fromDoc)
        .take(4)
        .toList();
  }
}
