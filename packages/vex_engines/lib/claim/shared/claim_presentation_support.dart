/// Human-readable claim and venue presentation helpers.
final class ClaimPresentationSupport {
  ClaimPresentationSupport._();

  /// Directory/search-card claim status label from raw venue metadata.
  static String directoryClaimStatusLabel(Map<String, dynamic> rawData) {
    final status = (rawData['claimStatus'] ?? rawData['claimedStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (status.isEmpty || status == 'unclaimed' || status == 'available') {
      return 'Unclaimed';
    }
    if (status == 'pending' || status == 'pending_review') {
      return 'Pending review';
    }
    return status[0].toUpperCase() + status.substring(1);
  }

  static String formatDisplayAddress({
    required String address,
    required String city,
    required String postcode,
    String emptyFallback = 'Address not listed',
  }) {
    final parts = [
      address,
      city,
      postcode,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? emptyFallback : parts.join(', ');
  }
}
