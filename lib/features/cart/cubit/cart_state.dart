part of 'cart_cubit.dart';

abstract class CartState {}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

// حالة إضافية للعمليات الجارية مثل الإضافة والحذف
class CartUpdating extends CartState {
  final String message;

  CartUpdating(this.message);
}

class CartSuccess extends CartState {
  final String message;

  CartSuccess([this.message = 'تمت العملية بنجاح']);
}

class CartLoaded extends CartState {
  final List<Map<String, dynamic>> cartItems;
  final double totalCartValue;

  CartLoaded(this.cartItems, this.totalCartValue);
}

class CartError extends CartState {
  final String message;

  CartError(this.message);
}
