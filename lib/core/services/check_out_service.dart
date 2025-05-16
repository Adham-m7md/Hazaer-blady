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

      // إعداد بيانات الطلب
      final orderData = {
        'userData': userData,
        'cartItems': cartItems,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      // كتابة الطلب إلى Firestore
      final orderRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .add(orderData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('انتهت مهلة إنشاء الطلب'),
          );

      // إرجاع رقم الطلب
      return orderRef.id;
    } catch (e, stackTrace) {
      // تسجيل الخطأ للتحقق
      print('Error in submitOrder: $e');
      print('StackTrace: $stackTrace');
      throw Exception('فشل إنشاء الطلب: $e');
    }
  }
}
