import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/cart_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartService _cartService = getIt<CartService>();
  StreamSubscription? _cartSubscription;
  List<Map<String, dynamic>> lastKnownItems = [];
  List<String> selectedItems = []; // قائمة لتخزين معرفات المنتجات المختارة

  CartCubit() : super(CartInitial());

  // إضافة منتج مع مراقبة حالة العملية
  Future<void> addToCart({
    required String productId,
    required Map<String, dynamic> productData,
    required int quantity,
    required double totalPrice,
  }) async {
    try {
      emit(CartUpdating('جاري إضافة المنتج...'));

      await _cartService.addToCart(
        productId: productId,
        productData: productData,
        quantity: quantity,
        totalPrice: totalPrice,
      );

      final newItem = {
        'productId': productId,
        'productData': productData,
        'quantity': quantity,
        'totalPrice': totalPrice,
      };

      final updatedItems = [...lastKnownItems];
      final existingIndex = updatedItems.indexWhere(
        (item) => item['productId'] == productId,
      );
      if (existingIndex >= 0) {
        updatedItems[existingIndex] = newItem;
      } else {
        updatedItems.add(newItem);
      }

      lastKnownItems = updatedItems;
      final totalCartValue = _calculateTotalCartValue(updatedItems);

      emit(CartLoaded(updatedItems, totalCartValue));
      emit(CartSuccess('تمت إضافة المنتج بنجاح'));

      await Future.delayed(const Duration(milliseconds: 300));
      _refreshCartItems();
    } catch (e) {
      if (lastKnownItems.isNotEmpty) {
        final totalCartValue = _calculateTotalCartValue(lastKnownItems);
        emit(CartLoaded(lastKnownItems, totalCartValue));
      }
      emit(CartError('فشل إضافة المنتج: ${e.toString()}'));
    }
  }

  // تحميل منتجات السلة مع الاشتراك في التغييرات
  void loadCartItems() {
    try {
      final previousState = state;
      if (previousState is! CartLoaded) {
        emit(CartLoading());
      }

      _refreshCartItems();
    } catch (e) {
      if (lastKnownItems.isNotEmpty) {
        final totalCartValue = _calculateTotalCartValue(lastKnownItems);
        emit(CartLoaded(lastKnownItems, totalCartValue));
      } else {
        emit(CartLoaded([], 0));
      }
    }
  }

  // دالة خاصة لتحديث بيانات السلة
  void _refreshCartItems() {
    _cartSubscription?.cancel();

    _cartSubscription = _cartService.getCartItems().listen(
      (items) {
        lastKnownItems = items;
        // إعادة ضبط المنتجات المختارة إذا كانت غير موجودة في القائمة الجديدة
        selectedItems.removeWhere(
          (id) => !items.any((item) => item['productId'] == id),
        );
        final totalCartValue = _calculateTotalCartValue(items);
        emit(CartLoaded(items, totalCartValue));
      },
      onError: (error) {
        if (lastKnownItems.isNotEmpty) {
          final totalCartValue = _calculateTotalCartValue(lastKnownItems);
          emit(CartLoaded(lastKnownItems, totalCartValue));
        } else {
          emit(CartLoaded([], 0));
        }
      },
    );
  }

  // حذف منتج من السلة مع تحسين تجربة المستخدم
  Future<void> removeFromCart(String productId) async {
    try {
      final currentState = state;
      List<Map<String, dynamic>> previousItems = [];

      if (currentState is CartLoaded) {
        previousItems = List<Map<String, dynamic>>.from(currentState.cartItems);

        final updatedItems = List<Map<String, dynamic>>.from(previousItems)
          ..removeWhere((item) => item['productId'] == productId);

        lastKnownItems = updatedItems;
        selectedItems.remove(productId); // إزالة المنتج من المنتجات المختارة
        final updatedTotal = _calculateTotalCartValue(updatedItems);

        emit(CartLoaded(updatedItems, updatedTotal));

        await _cartService.removeFromCart(productId);

        _refreshCartItems();
      } else {
        previousItems = List<Map<String, dynamic>>.from(lastKnownItems);
        final updatedItems = List<Map<String, dynamic>>.from(previousItems)
          ..removeWhere((item) => item['productId'] == productId);

        lastKnownItems = updatedItems;
        selectedItems.remove(productId); // إزالة المنتج من المنتجات المختارة
        final updatedTotal = _calculateTotalCartValue(updatedItems);
        emit(CartLoaded(updatedItems, updatedTotal));

        await _cartService.removeFromCart(productId);
        _refreshCartItems();
      }
    } catch (e) {
      if (lastKnownItems.isNotEmpty) {
        final totalCartValue = _calculateTotalCartValue(lastKnownItems);
        emit(CartLoaded(lastKnownItems, totalCartValue));
      } else {
        emit(CartLoaded([], 0));
      }
    }
  }

  // تفريغ السلة بالكامل
  Future<void> clearCart() async {
    try {
      emit(CartUpdating('جاري تفريغ السلة...'));
      await _cartService.clearCart();
      lastKnownItems = [];
      selectedItems = []; // إعادة ضبط المنتجات المختارة
      emit(CartLoaded([], 0));
    } catch (e) {
      if (lastKnownItems.isNotEmpty) {
        final totalCartValue = _calculateTotalCartValue(lastKnownItems);
        emit(CartLoaded(lastKnownItems, totalCartValue));
      } else {
        emit(CartLoaded([], 0));
      }
    }
  }

  // التحكم في اختيار/إلغاء اختيار منتج
  void toggleItemSelection(String productId) {
    if (selectedItems.contains(productId)) {
      selectedItems.remove(productId);
    } else {
      selectedItems.add(productId);
    }
    // إعادة إصدار الحالة لتحديث واجهة المستخدم
    final totalCartValue = _calculateTotalCartValue(lastKnownItems);
    emit(CartLoaded(lastKnownItems, totalCartValue));
  }

  // تحديد الكل
  void selectAllItems() {
    selectedItems =
        lastKnownItems.map((item) => item['productId'] as String).toList();
    final totalCartValue = _calculateTotalCartValue(lastKnownItems);
    emit(CartLoaded(lastKnownItems, totalCartValue));
  }

  // إلغاء تحديد الكل
  void deselectAllItems() {
    selectedItems = [];
    final totalCartValue = _calculateTotalCartValue(lastKnownItems);
    emit(CartLoaded(lastKnownItems, totalCartValue));
  }

  // إرجاع المنتجات المختارة
  List<Map<String, dynamic>> getSelectedItems() {
    return lastKnownItems
        .where((item) => selectedItems.contains(item['productId']))
        .toList();
  }

  // حساب القيمة الإجمالية للسلة بشكل آمن
  double _calculateTotalCartValue(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 0;

    return items.fold(0, (sum, item) {
      final price = item['totalPrice'];
      if (price is num) {
        return sum + price;
      }
      return sum;
    });
  }

  @override
  Future<void> close() async {
    await _cartSubscription?.cancel();
    return super.close();
  }
}
