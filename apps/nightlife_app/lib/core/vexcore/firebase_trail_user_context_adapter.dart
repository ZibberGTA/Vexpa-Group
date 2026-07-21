import 'package:firebase_auth/firebase_auth.dart';
import 'package:vex_engines/trail/trail_engine.dart';

/// Supplies authenticated user context for trail application services.
final class FirebaseTrailUserContextAdapter implements TrailUserContextPort {
  FirebaseTrailUserContextAdapter({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;

  @override
  TrailUserContext currentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const TrailUserContext(userId: null);
    }
    return TrailUserContext(
      userId: user.uid,
      isAnonymous: user.isAnonymous,
    );
  }
}
