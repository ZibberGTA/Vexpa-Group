import '../domain/claim_search_candidate.dart';
import '../shared/claim_search_support.dart';

/// Search limits shared by claim venue search adapters.
abstract final class ClaimSearchLimits {
  ClaimSearchLimits._();

  static const minQueryLength = 2;
  static const maxResults = 40;
  static const fallbackBatchSize = 150;
  static const fallbackMaxDocs = 900;
  static const directoryFetchLimit = 400;
  static const indexedTokenQueryLimit = 50;
  static const indexedPrefixQueryLimit = 40;
  static const indexedUnclaimedLimit = 120;
  static const maxIndexedTokens = 3;
}

/// Normalised claim search query tokens.
final class ClaimSearchQuery {
  const ClaimSearchQuery({required this.normalized, required this.tokens});

  final String normalized;
  final List<String> tokens;
}

/// Outcome of interpreting a raw venue search query.
sealed class ClaimSearchInterpretation {}

final class ClaimSearchReady extends ClaimSearchInterpretation {
  ClaimSearchReady(this.query);

  final ClaimSearchQuery query;
}

final class ClaimSearchTooShort extends ClaimSearchInterpretation {
  ClaimSearchTooShort();
}

/// Search orchestration: query interpretation, dedupe, ranking, and ordering.
final class ClaimSearchService {
  const ClaimSearchService();

  ClaimSearchInterpretation interpretQuery(String rawQuery) {
    final normalized = rawQuery.trim().toLowerCase();
    if (normalized.length < ClaimSearchLimits.minQueryLength) {
      return ClaimSearchTooShort();
    }
    return ClaimSearchReady(
      ClaimSearchQuery(
        normalized: normalized,
        tokens: ClaimSearchSupport.tokenize(normalized),
      ),
    );
  }

  List<String> indexedQueryTokens(ClaimSearchQuery query) {
    if (query.tokens.isEmpty) {
      return [query.normalized];
    }
    return query.tokens
        .take(ClaimSearchLimits.maxIndexedTokens)
        .toList(growable: false);
  }

  bool shouldCollectMore(int matchCount) =>
      matchCount < ClaimSearchLimits.maxResults;

  bool shouldContinueFallback({
    required int scannedDocuments,
    required int matchCount,
  }) =>
      scannedDocuments < ClaimSearchLimits.fallbackMaxDocs &&
      matchCount < ClaimSearchLimits.maxResults;

  /// Returns true when the candidate was accepted into [matches].
  bool tryMergeCandidate<T extends ClaimSearchCandidate>({
    required Map<String, T> matches,
    required T candidate,
    required String normalizedQuery,
    required List<String> tokens,
  }) {
    if (!ClaimSearchSupport.isClaimableVenue(candidate.rawData)) {
      return false;
    }
    if (!ClaimSearchSupport.matchesQuery(candidate, normalizedQuery, tokens)) {
      return false;
    }

    matches[candidate.venueId] = candidate;
    return true;
  }

  int rankScore(
    ClaimSearchCandidate candidate,
    String normalizedQuery,
    List<String> tokens,
  ) {
    var score = 0;
    final name = candidate.name.trim().toLowerCase();
    if (normalizedQuery.length >= ClaimSearchLimits.minQueryLength &&
        name.startsWith(normalizedQuery)) {
      score += 100;
    }
    if (tokens.isNotEmpty && tokens.every(name.contains)) {
      score += 50;
    }

    final haystack = ClaimSearchSupport.buildHaystack(candidate);
    if (haystack.contains(normalizedQuery)) {
      score += 10;
    }
    for (final token in tokens) {
      if (name.contains(token)) {
        score += 5;
      }
    }
    return score;
  }

  /// Deterministic ordering with first-seen tie preservation.
  List<T> finalizeResults<T extends ClaimSearchCandidate>(
    Iterable<T> candidates,
    ClaimSearchQuery query,
  ) {
    final list = candidates.toList(growable: false);
    if (list.length <= 1) {
      return list.take(ClaimSearchLimits.maxResults).toList(growable: false);
    }

    final firstSeenOrder = <String, int>{};
    for (var index = 0; index < list.length; index++) {
      firstSeenOrder.putIfAbsent(list[index].venueId, () => index);
    }

    final ranked = List<T>.from(list);
    ranked.sort((left, right) {
      final scoreDiff =
          rankScore(right, query.normalized, query.tokens) -
          rankScore(left, query.normalized, query.tokens);
      if (scoreDiff != 0) {
        return scoreDiff;
      }

      final orderDiff =
          (firstSeenOrder[left.venueId] ?? 0) -
          (firstSeenOrder[right.venueId] ?? 0);
      if (orderDiff != 0) {
        return orderDiff;
      }

      return left.venueId.compareTo(right.venueId);
    });

    return ranked.take(ClaimSearchLimits.maxResults).toList(growable: false);
  }

  /// Preferred search source when earlier tiers return candidates.
  String sourceLabelForTier({
    required bool usedDirectory,
    required bool usedIndexed,
  }) {
    if (usedDirectory) return 'venue_claim_directory';
    if (usedIndexed) return 'venues-indexed';
    return 'venues-fallback';
  }
}
