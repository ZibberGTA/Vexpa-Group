/// Authenticated user context for trail writes.
final class TrailUserContext {
  const TrailUserContext({required this.userId, this.isAnonymous = false});

  final String? userId;
  final bool isAnonymous;

  bool get isAuthenticated => userId != null && userId!.trim().isNotEmpty;
}

abstract interface class TrailUserContextPort {
  TrailUserContext currentUser();
}
