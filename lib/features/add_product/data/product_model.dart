import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id; // Add id field
  final String? name; // For products
  final String? title; // For offers
  final String? description;
  final double? pricePerKg; // For products
  final double? price; // For offers
  final String? imageUrl;
  final int? minWeight; // For products
  final int? maxWeight; // For products
  final double? quantity; // For products
  final double? totalPrice; // For products
  final String? displayLocation; // For offers
  final String? farmerId;
  final Timestamp? createdAt;

  ProductModel({
    required this.id,
    this.name,
    this.title,
    this.description,
    this.pricePerKg,
    this.price,
    this.imageUrl,
    this.minWeight,
    this.maxWeight,
    this.quantity,
    this.totalPrice,
    this.displayLocation,
    this.farmerId,
    this.createdAt,
  });

  // Factory constructor to create Product from Firestore map
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      pricePerKg: map['price_per_kg']?.toDouble(),
      price: map['price']?.toDouble(),
      imageUrl: map['image_url'] as String?,
      minWeight: map['min_weight'] as int?,
      maxWeight: map['max_weight'] as int?,
      quantity: map['quantity']?.toDouble(),
      totalPrice: map['total_price']?.toDouble(),
      displayLocation: map['display_location'] as String?,
      farmerId: map['farmer_id'] as String?,
      createdAt: map['created_at'] as Timestamp?,
    );
  }

  // Convert Product to Map for use in UI
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'title': title,
      'description': description,
      'price_per_kg': pricePerKg,
      'price': price,
      'image_url': imageUrl,
      'min_weight': minWeight,
      'max_weight': maxWeight,
      'quantity': quantity,
      'total_price': totalPrice,
      'display_location': displayLocation,
      'farmer_id': farmerId,
      'created_at': createdAt?.toDate().toIso8601String(),
    };
  }
}
