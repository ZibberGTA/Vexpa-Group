import '../data/pagination.dart';

/// Sort options matching current mobile list ordering needs.
enum TrailListSort {
  /// Newest `generatedAt` first (staff admin list).
  generatedAtDesc,

  /// Curated before generated, then highest `averageRating` (discovery).
  discoveryDefault,
}

/// Query for listing trail documents.
final class TrailListQuery {
  TrailListQuery({
    this.trailIds = const [],
    this.statuses = const [],
    this.publishedOnly = false,
    this.includeArchived = true,
    this.limit = 100,
    this.cursor,
    this.sort = TrailListSort.generatedAtDesc,
  }) : assert(limit > 0, 'limit must be positive'),
       assert(limit <= 500, 'limit must not exceed 500');

  final List<String> trailIds;
  final List<String> statuses;
  final bool publishedOnly;
  final bool includeArchived;
  final int limit;
  final String? cursor;
  final TrailListSort sort;
}

/// Query for listing user trail progress records.
final class TrailProgressListQuery {
  TrailProgressListQuery({
    required this.userId,
    this.trailIds = const [],
    this.activeOnly = false,
    this.completedOnly = false,
    this.limit = 25,
    this.cursor,
  }) : assert(userId.trim().isNotEmpty, 'userId must not be empty'),
       assert(limit > 0, 'limit must be positive'),
       assert(limit <= 200, 'limit must not exceed 200'),
       assert(
         !(activeOnly && completedOnly),
         'activeOnly and completedOnly are mutually exclusive',
       );

  final String userId;
  final List<String> trailIds;
  final bool activeOnly;
  final bool completedOnly;
  final int limit;
  final String? cursor;
}

/// Query for listing trail activity records.
final class TrailActivityListQuery {
  TrailActivityListQuery({
    this.userId,
    this.trailId,
    this.progressId,
    this.actions = const [],
    this.since,
    this.until,
    this.limit = 50,
    this.cursor,
  }) : assert(limit > 0, 'limit must be positive'),
       assert(limit <= 500, 'limit must not exceed 500');

  final String? userId;
  final String? trailId;
  final String? progressId;
  final List<String> actions;
  final DateTime? since;
  final DateTime? until;
  final int limit;
  final String? cursor;
}

/// Pagination wrapper for trail list results.
typedef TrailPage<T> = Page<T>;

/// Pagination request helper for trail queries.
typedef TrailPageRequest = PageRequest;
