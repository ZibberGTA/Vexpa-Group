/// Partial field updates applied in bulk to selected drinks.
class BulkDrinkPatch {
  const BulkDrinkPatch({
    this.name,
    this.category,
    this.price,
    this.available,
    this.featured,
  });

  final String? name;
  final String? category;
  final double? price;
  final bool? available;
  final bool? featured;

  bool get isEmpty =>
      name == null &&
      category == null &&
      price == null &&
      available == null &&
      featured == null;
}
