/// Paid venue visibility boost product.
final class BoostPlan {
  const BoostPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.days,
    required this.boostScore,
    required this.priceLabel,
    required this.pricePence,
  });

  final String id;
  final String name;
  final String description;
  final int days;
  final int boostScore;
  final String priceLabel;
  final int pricePence;
}
