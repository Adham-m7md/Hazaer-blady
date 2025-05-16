import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/get_it.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = getIt<FirebaseAuthService>();
  final AppLogger _logger = AppLogger('CartService');

  // إضافة منتج إلى السلة مع التحقق من وجوده مسبقاً
  Future<void> addToCart({
    required String productId,
    required Map<String, dynamic> productData,
    required int quantity,
    required double totalPrice,
  }) async {
    try {
      final userId = _authService.getCurrentUser()?.uid;
      _logger.info('Adding to cart: userId=$userId, productId=$productId');
      if (userId == null || userId.isEmpty) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }
      if (productId.isEmpty) {
        throw Exception('معرف المنتج غير صالح');
      }

      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId);

      final existingItem = await cartRef.get();

      if (existingItem.exists) {
        final existingQuantity = existingItem.data()?['quantity'] ?? 0;
        final newQuantity = existingQuantity + quantity;
        final newTotalPrice =
            (productData['price_per_kg'] ?? 0.0) *
            ((productData['min_weight'] ?? 0.0) +
                (productData['max_weight'] ?? 0.0)) /
            2 *
            newQuantity;

        await cartRef.update({
          'quantity': newQuantity,
          'totalPrice': newTotalPrice,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _logger.info(
          'تم تحديث المنتج في السلة: $productId، الكمية الجديدة: $newQuantity',
        );
      } else {
        await cartRef.set({
          'productId': productId,
          'productData': productData,
          'quantity': quantity,
          'totalPrice': totalPrice,
          'addedAt': FieldValue.serverTimestamp(),
        });

        _logger.info('تمت إضافة منتج جديد إلى السلة: $productId');
      }
    } catch (e) {
      _logger.error('فشل في إضافة المنتج إلى السلة: $e');
      throw Exception('فشل في إضافة المنتج إلى السلة: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getCartItems() async* {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _logger.error('لا يوجد اتصال بالإنترنت');
      yield [];
      return;
    }

    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) {
      _logger.warning('محاولة الوصول إلى السلة بدون تسجيل دخول');
      yield [];
      return;
    }

    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: (sink) {
            _logger.error('انتهت مهلة جلب محتويات السلة');
            sink.addError(
              'انتهت مهلة جلب محتويات السلة، تحقق من اتصالك بالإنترنت',
            );
          },
        )
        .map((snapshot) {
          final items =
              snapshot.docs.map((doc) {
                final data = doc.data();
                if (!data.containsKey('productData') ||
                    data['productData'] == null) {
                  _logger.warning('منتج بدون بيانات في السلة: ${doc.id}');
                  data['productData'] = {
                    'name': 'منتج غير متوفر',
                    'image_url': '',
                  };
                }
                return data;
              }).toList();

          _logger.info('تم جلب ${items.length} منتج من السلة');
          return items;
        });
  }

  // حذف منتج من السلة مع التحقق من الصلاحيات
  Future<void> removeFromCart(String productId) async {
    try {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId == null) throw Exception('يجب تسجيل الدخول أولاً');

      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId);

      // التحقق من وجود المنتج
      final doc = await cartRef.get();
      if (!doc.exists) {
        _logger.warning('محاولة حذف منتج غير موجود في السلة: $productId');
        return;
      }

      await cartRef.delete();
      _logger.info('تم حذف المنتج من السلة: $productId');
    } catch (e) {
      _logger.error('فشل في حذف المنتج من السلة: $e');
      throw Exception('فشل في حذف المنتج من السلة: $e');
    }
  }

  // تفريغ السلة مع عمليات متوازية
  Future<void> clearCart() async {
    try {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId == null) throw Exception('يجب تسجيل الدخول أولاً');

      final cartItems =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('cart')
              .get();

      if (cartItems.docs.isEmpty) {
        _logger.info('السلة فارغة بالفعل');
        return;
      }

      // حذف متوازي لجميع العناصر
      final batch = _firestore.batch();
      for (var doc in cartItems.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _logger.info(
        'تم تفريغ السلة بنجاح، تم حذف ${cartItems.docs.length} منتج',
      );
    } catch (e) {
      _logger.error('فشل في تفريغ السلة: $e');
      throw Exception('فشل في تفريغ السلة: $e');
    }
  }
}

class AppLogger {
  final String _tag;

  AppLogger(this._tag);

  void info(String message) {
    _log('INFO', message);
  }

  void warning(String message) {
    _log('WARNING', message);
  }

  void error(String message) {
    _log('ERROR', message);
  }

  void _log(String level, String message) {
    if (kDebugMode) {
      print('[$level] $_tag: $message');
    }
  }
}
