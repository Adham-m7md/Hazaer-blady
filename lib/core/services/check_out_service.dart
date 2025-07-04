import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutService {
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

      // إعداد بيانات الطلب
      final orderData = {
        'userData': userData,
        'cartItems': cartItems,
        'farmer_id': farmerId,
        'user_id': user.uid, // إضافة معرف المشتري
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
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

      // إرجاع رقم الطلب
      return orderRef.id;
    } catch (e, stackTrace) {
      print('Error in submitOrder: $e');
      print('StackTrace: $stackTrace');
      throw Exception('فشل إنشاء الطلب: $e');
    }
  }
}
