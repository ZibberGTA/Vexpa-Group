enum SearchOutcomeStatus {
  success,
  empty,
  loadFailed,
  offline,
}

class SearchOutcome {
  const SearchOutcome({
    required this.results,
    required this.status,
  });

  SearchOutcome.success(List<Map<String, dynamic>> results)
      : results = results,
        status = results.isEmpty
            ? SearchOutcomeStatus.empty
            : SearchOutcomeStatus.success;

  const SearchOutcome.failure(SearchOutcomeStatus status)
      : results = const [],
        status = status;

  final List<Map<String, dynamic>> results;
  final SearchOutcomeStatus status;

  bool get isLoadingFailure =>
      status == SearchOutcomeStatus.loadFailed ||
      status == SearchOutcomeStatus.offline;
}
