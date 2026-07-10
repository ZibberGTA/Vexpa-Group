final class PageRequest {
  const PageRequest({this.limit = 25, this.cursor});

  final int limit;
  final String? cursor;
}

final class Page<T> {
  const Page({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}
