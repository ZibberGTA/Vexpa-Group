import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_role_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool get isGuestUser => _auth.currentUser?.isAnonymous ?? false;

  static Future<void> signInAnonymouslyIfNeeded() async {
    if (_auth.currentUser != null) return;

    final credential = await _auth.signInAnonymously();
    await _ensureGuestUserDocument(credential.user);
  }

  static Future<void> _ensureGuestUserDocument(User? user) async {
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': 'Guest User',
      'role': 'guest',
      'isGuest': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    UserCredential credential;
    final currentUser = _auth.currentUser;
    final authCredential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password.trim(),
    );

    if (currentUser != null && currentUser.isAnonymous) {
      credential = await currentUser.linkWithCredential(authCredential);
    } else {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    }

    final User? user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User account could not be created.',
      );
    }

    await user.updateDisplayName(name.trim());

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim(),
      'role': _normaliseRole(role),
      'isGuest': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    if (_auth.currentUser?.isAnonymous ?? false) {
      await _auth.signOut();
    }

    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    final currentUser = _auth.currentUser;
    UserCredential credential;

    if (currentUser != null && currentUser.isAnonymous) {
      credential = await currentUser.linkWithProvider(provider);
    } else {
      credential = await _auth.signInWithProvider(provider);
    }

    await _ensureUserDocument(credential.user);
  }

  static Future<void> signInWithMicrosoft() async {
    final provider = OAuthProvider('microsoft.com')
      ..addScope('openid')
      ..addScope('email')
      ..addScope('profile')
      ..setCustomParameters({'tenant': 'common'});

    final currentUser = _auth.currentUser;
    UserCredential credential;

    if (currentUser != null && currentUser.isAnonymous) {
      credential = await currentUser.linkWithProvider(provider);
    } else {
      credential = await _auth.signInWithProvider(provider);
    }

    await _ensureUserDocument(credential.user);
  }

  static Future<void> _ensureUserDocument(User? user) async {
    if (user == null) return;

    final ref = _firestore.collection('users').doc(user.uid);
    final existing = await ref.get();

    await ref.set({
      'uid': user.uid,
      'name': user.displayName ?? user.email?.split('@').first ?? 'User',
      'email': user.email,
      'role': existing.data()?['role'] == 'guest'
          ? 'user'
          : (existing.data()?['role'] ?? 'user'),
      'isGuest': false,
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


  static String getLocalDisplayName() {
    final user = currentUser;
    if (user == null) return 'Owner';

    final firebaseName = user.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName;
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Owner';
  }

  static Future<String> getCurrentUserDisplayName() async {
    final user = currentUser;
    if (user == null) return 'Owner';

    final firebaseName = user.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      final firestoreName = data?['name']?.toString().trim();

      if (firestoreName != null && firestoreName.isNotEmpty) {
        await user.updateDisplayName(firestoreName);
        return firestoreName;
      }
    } catch (_) {
      // Fall back to local Firebase Auth data below.
    }

    return getLocalDisplayName();
  }

  static Future<String?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    final role = UserRoleService.parseRole(data?['role']);
    return UserRoleService.roleToFirestoreValue(role);
  }

  static String _normaliseRole(String role) {
    final parsed = UserRoleService.parseRole(role);
    return UserRoleService.roleToFirestoreValue(parsed);
  }
}