class DrinkModel {
  final String id;
  final String venueId;
  final String name;
  final String category;
  final double price;
  final String description;
  final bool available;
  final bool isDeleted;

  DrinkModel({
    required this.id,
    required this.venueId,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.available,
    required this.isDeleted,
  });

  factory DrinkModel.fromMap(String id, Map<String, dynamic> map) {
    final rawPrice = map['price'];

    double parsedPrice = 0;

    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is String) {
      parsedPrice = double.tryParse(rawPrice) ?? 0;
    }

    return DrinkModel(
      id: id,
      venueId: map['venueId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      price: parsedPrice,
      description: map['description']?.toString() ?? '',
      available: map['available'] == true,
      isDeleted: map['isDeleted'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'available': available,
      'isDeleted': isDeleted,
    };
  }

  String get formattedPrice => '£${price.toStringAsFixed(2)}';
}