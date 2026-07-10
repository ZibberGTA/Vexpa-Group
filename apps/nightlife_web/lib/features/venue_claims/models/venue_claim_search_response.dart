import 'venue_claim.dart';

/// Result of a venue claim search — never silently maps errors to empty results.
class VenueClaimSearchResponse {
  const VenueClaimSearchResponse({
    required this.results,
    required this.success,
    this.errorMessage,
    this.source = 'unknown',
    this.scannedCount = 0,
  });

  final List<VenueClaimSearchResult> results;
  final bool success;
  final String? errorMessage;
  final String source;
  final int scannedCount;

  bool get hasError => !success && (errorMessage?.isNotEmpty ?? false);

  factory VenueClaimSearchResponse.failure(
    String message, {
    String source = 'error',
  }) {
    return VenueClaimSearchResponse(
      results: const [],
      success: false,
      errorMessage: message,
      source: source,
    );
  }

  factory VenueClaimSearchResponse.ok(
    List<VenueClaimSearchResult> results, {
    required String source,
    int scannedCount = 0,
  }) {
    return VenueClaimSearchResponse(
      results: results,
      success: true,
      source: source,
      scannedCount: scannedCount,
    );
  }
}
