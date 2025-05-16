// File: product_details_state.dart
import 'package:equatable/equatable.dart';

enum ProductDetailsStatus { initial, loading, loaded, error }

class ProductDetailsState extends Equatable {
  const ProductDetailsState({
    this.status = ProductDetailsStatus.initial,
    this.productData,
    this.quantity = 1000,
    this.errorMessage,
  });

  const ProductDetailsState.initial() : this();

  final ProductDetailsStatus status;
  final Map<String, dynamic>? productData;
  final int quantity;
  final String? errorMessage;

  ProductDetailsState copyWith({
    ProductDetailsStatus? status,
    Map<String, dynamic>? productData,
    int? quantity,
    String? errorMessage,
  }) {
    return ProductDetailsState(
      status: status ?? this.status,
      productData: productData ?? this.productData,
      quantity: quantity ?? this.quantity,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, productData, quantity, errorMessage];
}
