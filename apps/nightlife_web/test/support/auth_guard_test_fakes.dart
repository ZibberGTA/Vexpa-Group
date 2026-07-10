import 'dart:async';

import 'package:vex_core/vex_core.dart';

/// Tracks stream listener counts and replays the latest value to new listeners.
final class StreamListenTracker<T> {
  StreamListenTracker({T? seedValue}) {
    if (seedValue != null || seedValue == null && false) {
      // no-op: seed via emit() in fakes
    }
  }

  late final StreamController<T> _controller = StreamController<T>.broadcast(
    onListen: () {
      activeListeners++;
      if (activeListeners > maxConcurrentListeners) {
        maxConcurrentListeners = activeListeners;
      }
      listenCount++;
      if (_hasValue) {
        _controller.add(_lastValue as T);
      }
    },
    onCancel: () {
      activeListeners--;
    },
  );

  int activeListeners = 0;
  int maxConcurrentListeners = 0;
  int listenCount = 0;
  bool _hasValue = false;
  T? _lastValue;

  Stream<T> get stream => _controller.stream;

  void emit(T value) {
    _hasValue = true;
    _lastValue = value;
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }

  void emitError(Object error) {
    if (!_controller.isClosed) {
      _controller.addError(error);
    }
  }

  Future<void> close() async {
    await _controller.close();
  }
}

/// Fake [AuthenticationService] for AuthGuard widget tests.
final class FakeAuthenticationService implements AuthenticationService {
  FakeAuthenticationService({AuthenticatedUser? initialUser}) {
    if (initialUser != null) {
      emitAuthState(initialUser);
    }
  }

  final StreamListenTracker<AuthenticatedUser?> _authTracker =
      StreamListenTracker<AuthenticatedUser?>();

  AuthenticatedUser? _currentUser;

  @override
  Stream<AuthenticatedUser?> get authStateChanges => _authTracker.stream;

  @override
  AuthenticatedUser? get currentUser => _currentUser;

  int get authListenCount => _authTracker.listenCount;

  int get maxConcurrentAuthListeners => _authTracker.maxConcurrentListeners;

  void emitAuthState(AuthenticatedUser? user) {
    _currentUser = user;
    _authTracker.emit(user);
  }

  @override
  Future<AuthenticatedUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = AuthenticatedUser(uid: 'signed-in', email: email);
    emitAuthState(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    emitAuthState(null);
  }

  Future<void> dispose() => _authTracker.close();
}

/// Fake [IdentityService] for AuthGuard widget tests.
final class FakeIdentityService implements IdentityService {
  FakeIdentityService({
    VexIdentity? initialIdentity,
    this.retryDelay = Duration.zero,
    this.retryThrows = false,
  }) : _cachedIdentities = {
         if (initialIdentity != null) initialIdentity.uid: initialIdentity,
       } {
    if (initialIdentity != null) {
      emitIdentity(initialIdentity);
    }
  }

  final StreamListenTracker<VexIdentity?> _identityTracker =
      StreamListenTracker<VexIdentity?>();

  final Map<String, VexIdentity> _cachedIdentities;
  final Duration retryDelay;
  bool retryThrows;

  int retryCallCount = 0;
  VexIdentity? retryResult;

  @override
  Stream<VexIdentity?> get currentIdentityStream => _identityTracker.stream;

  int get identityListenCount => _identityTracker.listenCount;

  int get maxConcurrentIdentityListeners =>
      _identityTracker.maxConcurrentListeners;

  void emitIdentity(VexIdentity? identity) {
    if (identity != null) {
      _cachedIdentities[identity.uid] = identity;
    }
    _identityTracker.emit(identity);
  }

  void emitStreamError(Object error) {
    _identityTracker.emitError(error);
  }

  void cacheIdentity(VexIdentity identity) {
    _cachedIdentities[identity.uid] = identity;
  }

  @override
  VexIdentity? peekCachedIdentity(String uid) => _cachedIdentities[uid];

  @override
  Future<VexIdentity?> resolveCurrentIdentity() async {
    return _cachedIdentities.values.cast<VexIdentity?>().firstOrNull;
  }

  @override
  Future<VexIdentity?> resolveIdentity(String uid) async {
    return _cachedIdentities[uid];
  }

  @override
  Future<VexIdentity?> retryIdentityResolution(String uid) async {
    retryCallCount++;
    if (retryDelay > Duration.zero) {
      await Future<void>.delayed(retryDelay);
    }
    if (retryThrows) {
      throw StateError('identity resolution failed');
    }
    final identity = retryResult ?? _cachedIdentities[uid];
    if (identity != null) {
      cacheIdentity(identity);
      emitIdentity(identity);
    }
    return identity;
  }

  Future<void> dispose() => _identityTracker.close();
}

VexIdentity testIdentity({
  required String uid,
  required DashboardRole dashboardRole,
  AccountStatus status = AccountStatus.active,
  int roleLevel = 0,
  bool staffFlag = false,
}) {
  return VexIdentity.fromProfile(
    uid: uid,
    email: '$uid@example.com',
    dashboardRole: dashboardRole,
    status: status,
    roleLevel: roleLevel,
    staffFlag: staffFlag,
    isAdminFlag: dashboardRole == DashboardRole.admin,
  );
}

const testAuthenticatedUser = AuthenticatedUser(
  uid: 'user-1',
  email: 'user-1@example.com',
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
