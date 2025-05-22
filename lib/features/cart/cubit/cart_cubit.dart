import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/cart_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartService _cartService = getIt<CartService>();
  StreamSubscription? _cartSubscription;
  List<Map<String, dynamic>> lastKnownItems = [];

  CartCubit() : super(CartInitial());

  // إضافة منتج مع مراقبة حالة العملية
  Future<void> addToCart({
    required String productId,
    required Map<String, dynamic> productData,
    required int quantity,
    required double totalPrice,
  }) async {
    try {
      // استخدام CartUpdating بدلاً من CartLoading للتمييز بين العمليات
      emit(CartUpdating('جاري إضافة المنتج...'));

      await _cartService.addToCart(
        productId: productId,
        productData: productData,
        quantity: quantity,
        totalPrice: totalPrice,
      );

      // إضافة المنتج مؤقتًا إلى _lastKnownItems لضمان استمرارية العرض
      final newItem = {
        'productId': productId,
        'productData': productData,
        'quantity': quantity,
        'totalPrice': totalPrice,
      };

      final updatedItems = [...lastKnownItems];
      // تحقق ما إذا كان المنتج موجودًا بالفعل
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

      // تحديث قائمة المنتجات بعد الإضافة بعد فترة قصيرة
      await Future.delayed(const Duration(milliseconds: 300));
      _refreshCartItems();
    } catch (e) {
      // في حالة الخطأ، استعادة الحالة السابقة إذا كانت معروفة
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
      // الحفاظ على الحالة القديمة إذا كانت محملة مسبقًا
      final previousState = state;
      if (previousState is! CartLoaded) {
        emit(CartLoading());
      }

      _refreshCartItems();
    } catch (e) {
      // في حالة الخطأ، استعادة الحالة السابقة إذا كانت معروفة
      if (lastKnownItems.isNotEmpty) {
        final totalCartValue = _calculateTotalCartValue(lastKnownItems);
        emit(CartLoaded(lastKnownItems, totalCartValue));
      } else {
        emit(CartError('خطأ في تحميل السلة: ${e.toString()}'));
      }
    }
  }

  // دالة خاصة لتحديث بيانات السلة
  void _refreshCartItems() {
    // إلغاء الاشتراك السابق إن وجد
    _cartSubscription?.cancel();

    // الاشتراك في تدفق بيانات السلة
    _cartSubscription = _cartService.getCartItems().listen(
      (items) {
        lastKnownItems = items;
        final totalCartValue = _calculateTotalCartValue(items);
        emit(CartLoaded(items, totalCartValue));
      },
      onError: (error) {
        // لو الخطأ بسبب مهلة زمنية أو مشكلة إنترنت
        if (lastKnownItems.isNotEmpty) {
          final totalCartValue = _calculateTotalCartValue(lastKnownItems);
          emit(CartLoaded(lastKnownItems, totalCartValue));
        } else {
          emit(CartError('خطأ في تحميل السلة: ${error.toString()}'));
        }
      },
    );
  }

  // حذف منتج من السلة مع تحسين تجربة المستخدم
  Future<void> removeFromCart(String productId) async {
    try {
      // الاحتفاظ بالحالة الحالية للسلة قبل الحذف
      final currentState = state;
      List<Map<String, dynamic>> previousItems = [];

      if (currentState is CartLoaded) {
        previousItems = List<Map<String, dynamic>>.from(currentState.cartItems);

        // إنشاء نسخة من القائمة الحالية وإزالة المنتج منها نظريًا (للتحديث السريع)
        final updatedItems = List<Map<String, dynamic>>.from(previousItems)
          ..removeWhere((item) => item['productId'] == productId);

        lastKnownItems = updatedItems;
        final updatedTotal = _calculateTotalCartValue(updatedItems);

        // تحديث واجهة المستخدم مباشرة قبل الانتظار للاستجابة من الخادم
        emit(CartLoaded(updatedItems, updatedTotal));

        // تنفيذ عملية الحذف الفعلية على الخادم
        await _cartService.removeFromCart(productId);

        // تحديث القائمة بعد الحذف
        _refreshCartItems();
      } else {
        // استخدام _lastKnownItems إذا كان متاحًا
        previousItems = List<Map<String, dynamic>>.from(lastKnownItems);
        final updatedItems = List<Map<String, dynamic>>.from(previousItems)
          ..removeWhere((item) => item['productId'] == productId);

        lastKnownItems = updatedItems;
        final updatedTotal = _calculateTotalCartValue(updatedItems);
        emit(CartLoaded(updatedItems, updatedTotal));

        // تنفيذ عملية الحذف الفعلية
        await _cartService.removeFromCart(productId);
        _refreshCartItems();
      }
    } catch (e) {
      // في حالة الخطأ، استخدم آخر بيانات معروفة
      if (lastKnownItems.isNotEmpty) {
        final totalCartValue = _calculateTotalCartValue(lastKnownItems);
        emit(CartLoaded(lastKnownItems, totalCartValue));
      }
      emit(CartError('فشل حذف المنتج: ${e.toString()}'));
    }
  }

  // تفريغ السلة بالكامل
  Future<void> clearCart() async {
    try {
      emit(CartUpdating('جاري تفريغ السلة...'));
      await _cartService.clearCart();
      lastKnownItems = [];
      emit(CartLoaded([], 0));
    } catch (e) {
      // في حالة الخطأ، استخدم آخر بيانات معروفة
      if (lastKnownItems.isNotEmpty) {
        final totalCartValue = _calculateTotalCartValue(lastKnownItems);
        emit(CartLoaded(lastKnownItems, totalCartValue));
      }
      emit(CartError('فشل تفريغ السلة: ${e.toString()}'));
    }
  }

  // حساب القيمة الإجمالية للسلة بشكل آمن
  double _calculateTotalCartValue(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 0;

    return items.fold(0, (sum, item) {
      // التعامل مع القيم الفارغة بشكل آمن
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
