/// Minimal venue fields required for client-side discovery text matching.
class DiscoveryVenueCatalogEntry {
  const DiscoveryVenueCatalogEntry({
    required this.name,
    required this.category,
    required this.crowdLevel,
    required this.address,
    required this.searchTerms,
  });

  final String name;
  final String category;
  final String crowdLevel;
  final String address;
  final List<String> searchTerms;
}
