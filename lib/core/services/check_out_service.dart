import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CheckoutService {
  static const _adminEmail = 'ahmed.roma22@gmail.com';

  Future<String> submitOrder({
    required Map<String, String> userData,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      // التحقق من الاتصال بالإنترنت
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }

      // التحقق من تسجيل الدخول
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول لإتمام الطلب');
      }

      // التحقق من البيانات
      if (cartItems.isEmpty) {
        throw Exception('السلة فارغة');
      }
      if (userData.isEmpty) {
        throw Exception('بيانات المستخدم غير مكتملة');
      }

      // استخراج farmer_id من أول عنصر في cartItems
      final farmerId =
          cartItems.first['productData']['farmer_id'] as String? ??
          cartItems.first['productData']['farmerId'] as String?;
      if (farmerId == null || farmerId.isEmpty) {
        throw Exception('معرف صاحب الحظيرة غير متوفر في عناصر السلة');
      }

      // التحقق من أن جميع العناصر في السلة تخص نفس صاحب الحظيرة
      for (var item in cartItems) {
        final itemFarmerId =
            item['productData']['farmer_id'] as String? ??
            item['productData']['farmerId'] as String?;
        if (itemFarmerId != farmerId) {
          throw Exception('يجب أن تكون جميع العناصر من نفس صاحب الحظيرة');
        }
      }

      // التأكد من حفظ FCM token للمستخدم الحالي
      await _ensureUserFCMToken(user.uid);

      // إعداد بيانات الطلب
      final orderData = {
        'userData': userData,
        'cartItems': cartItems,
        'farmer_id': farmerId,
        'user_id': user.uid, // إضافة معرف المشتري
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(), // لتسهيل الترتيب
      };

      // كتابة الطلب إلى Firestore (للمستخدم)
      final orderRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .add(orderData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('انتهت مهلة إنشاء الطلب'),
          );

      // كتابة الطلب إلى Firestore (لصاحب الحظيرة)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(farmerId)
          .collection('farmer_orders')
          .doc(orderRef.id) // استخدام نفس orderId لتسهيل التتبع
          .set(orderData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('انتهت مهلة إنشاء الطلب'),
          );

      // التأكد من حفظ FCM token للمزارع (لإرسال الإشعارات)
      await _ensureUserFCMToken(farmerId);

      // إضافة: إرسال الطلب للأدمن إذا كانت المنتجات من Custom Products
      await _sendOrderToAdminIfCustomProduct(orderRef.id, orderData, cartItems);

      print('✅ Order created successfully: ${orderRef.id}');

      // إرجاع رقم الطلب
      return orderRef.id;
    } catch (e, stackTrace) {
      print('Error in submitOrder: $e');
      print('StackTrace: $stackTrace');
      throw Exception('فشل إنشاء الطلب: $e');
    }
  }

  // دالة جديدة لإرسال الطلب للأدمن إذا كانت المنتجات من Custom Products
  Future<void> _sendOrderToAdminIfCustomProduct(
    String orderId,
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> cartItems,
  ) async {
    try {
      // التحقق من أن المنتجات من Custom Products (offers collection)
      bool isCustomProduct = false;

      for (var item in cartItems) {
        final productData = item['productData'] as Map<String, dynamic>?;
        if (productData != null) {
          // التحقق من وجود المنتج في offers collection
          final productId = productData['id'] as String?;
          if (productId != null) {
            final offerDoc =
                await FirebaseFirestore.instance
                    .collection('offers')
                    .doc(productId)
                    .get();

            if (offerDoc.exists) {
              isCustomProduct = true;
              break;
            }
          }
        }
      }

      // إذا كانت المنتجات من Custom Products، أرسل للأدمن
      if (isCustomProduct) {
        // البحث عن الأدمن بالإيميل
        final adminQuery =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: _adminEmail)
                .limit(1)
                .get();

        if (adminQuery.docs.isNotEmpty) {
          final adminDoc = adminQuery.docs.first;
          final adminId = adminDoc.id;

          // إضافة الطلب إلى farmer_orders الخاص بالأدمن
          await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('farmer_orders')
              .doc(orderId)
              .set({
                ...orderData,
                'is_custom_product_order':
                    true, // علامة لتمييز طلبات Custom Products
                'admin_notification': true,
              });

          // التأكد من حفظ FCM token للأدمن
          await _ensureUserFCMToken(adminId);

          print('✅ Custom product order sent to admin: $orderId');
        } else {
          print('⚠️ Admin not found with email: $_adminEmail');
        }
      }
    } catch (e) {
      print('Error sending order to admin: $e');
      // لا نرمي خطأ هنا لأن عدم إرسال الطلب للأدمن لا يجب أن يوقف عملية إنشاء الطلب
    }
  }

  // دالة للتأكد من حفظ FCM token للمستخدم
  Future<void> _ensureUserFCMToken(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final existingToken = userData?['fcmToken'];

        // الحصول على FCM token الحالي
        final currentToken = await FirebaseMessaging.instance.getToken();

        // تحديث التوكن إذا كان مختلفاً أو غير موجود
        if (currentToken != null && currentToken != existingToken) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
                'fcmToken': currentToken,
                'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
              });

          print('FCM Token updated for user: $userId');
        }
      }
    } catch (e) {
      print('Error updating FCM token for user $userId: $e');
      // لا نرمي خطأ هنا لأن عدم تحديث التوكن لا يجب أن يوقف عملية إنشاء الطلب
    }
  }

  // دالة لتحديث حالة الطلب
  Future<void> updateOrderStatus({
    required String orderId,
    required String userId,
    required String farmerId,
    required String newStatus,
    String? adminId, // إضافة معرف الأدمن كمعامل اختياري
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // تحديث الطلب في مجموعة المستخدم
      final userOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId);

      // تحديث الطلب في مجموعة المزارع
      final farmerOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(farmerId)
          .collection('farmer_orders')
          .doc(orderId);

      batch.update(userOrderRef, {
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(farmerOrderRef, {
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      // تحديث الطلب في مجموعة الأدمن إذا كان موجوداً
      if (adminId != null) {
        final adminOrderRef = FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('farmer_orders')
            .doc(orderId);

        batch.update(adminOrderRef, {
          'status': newStatus,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      print('✅ Order status updated: $orderId -> $newStatus');
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('فشل تحديث حالة الطلب: $e');
    }
  }

  // دالة للحصول على تفاصيل الطلب
  Future<Map<String, dynamic>?> getOrderDetails({
    required String orderId,
    required String userId,
  }) async {
    try {
      final orderDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc(orderId)
              .get();

      if (orderDoc.exists) {
        return orderDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting order details: $e');
      return null;
    }
  }

  // دالة للحصول على جميع طلبات المستخدم
  Stream<QuerySnapshot> getUserOrders(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // دالة للحصول على عدد الطلبات غير المقروءة للمزارع
  Future<int> getUnreadOrdersCount(String farmerId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(farmerId)
              .collection('farmer_orders')
              .where('status', isEqualTo: 'pending')
              .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread orders count: $e');
      return 0;
    }
  }

  // دالة لتحديث حالة قراءة الطلب
  Future<void> markOrderAsRead({
    required String orderId,
    required String farmerId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(farmerId)
          .collection('farmer_orders')
          .doc(orderId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Error marking order as read: $e');
    }
  }

  // دالة جديدة للحصول على معرف الأدمن
  Future<String?> getAdminId() async {
    try {
      final adminQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: _adminEmail)
              .limit(1)
              .get();

      if (adminQuery.docs.isNotEmpty) {
        return adminQuery.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error getting admin ID: $e');
      return null;
    }
  }
}
