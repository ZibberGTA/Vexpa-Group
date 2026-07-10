import 'package:cloud_firestore/cloud_firestore.dart';

class DrinkModel {
  const DrinkModel({
    required this.id,
    required this.venueId,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.available,
    required this.featured,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String venueId;
  final String name;
  final String category;
  final double price;
  final String description;
  final bool available;
  final bool featured;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  factory DrinkModel.fromMap(String id, Map<String, dynamic> map) {
    final rawPrice = map['price'];
    var parsedPrice = 0.0;

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
      featured: map['featured'] == true || map['isFeatured'] == true,
      isDeleted: map['isDeleted'] == true,
      createdAt: _timestampToDate(map['createdAt']),
      updatedAt: _timestampToDate(map['updatedAt']),
      createdBy: map['createdBy']?.toString(),
    );
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  bool get hasValidPrice {
    if (price.isNaN || !price.isFinite) return false;
    return price > 0;
  }

  String get formattedPrice =>
      hasValidPrice ? '£${price.toStringAsFixed(2)}' : '—';

  /// Spreadsheet export value — blank unless the drink has a genuine price.
  String get exportPriceValue =>
      hasValidPrice ? price.toStringAsFixed(2) : '';
}
