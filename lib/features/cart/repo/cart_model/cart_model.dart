import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final String description;
  final double pricePerKg;
  final double minWeight;
  final double maxWeight;
  final int quantity;
  final double totalPrice;
  final String farmerId;
  final Timestamp addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.description,
    required this.pricePerKg,
    required this.minWeight,
    required this.maxWeight,
    required this.quantity,
    required this.totalPrice,
    required this.farmerId,
    required this.addedAt,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id,
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      imageUrl: data['image_url'] ?? '',
      description: data['description'] ?? '',
      pricePerKg: (data['price_per_kg'] as num?)?.toDouble() ?? 0.0,
      minWeight: (data['min_weight'] as num?)?.toDouble() ?? 0.0,
      maxWeight: (data['max_weight'] as num?)?.toDouble() ?? 0.0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      totalPrice: (data['total_price'] as num?)?.toDouble() ?? 0.0,
      farmerId: data['farmer_id'] ?? '',
      addedAt: data['added_at'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'product_name': productName,
      'image_url': imageUrl,
      'description': description,
      'price_per_kg': pricePerKg,
      'min_weight': minWeight,
      'max_weight': maxWeight,
      'quantity': quantity,
      'total_price': totalPrice,
      'farmer_id': farmerId,
      'added_at': addedAt,
    };
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? imageUrl,
    String? description,
    double? pricePerKg,
    double? minWeight,
    double? maxWeight,
    int? quantity,
    double? totalPrice,
    String? farmerId,
    Timestamp? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      minWeight: minWeight ?? this.minWeight,
      maxWeight: maxWeight ?? this.maxWeight,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      farmerId: farmerId ?? this.farmerId,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
