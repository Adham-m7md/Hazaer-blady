import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class FarmerOrderService {
  Stream<QuerySnapshot> getFarmerOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول لعرض الطلبات');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('farmer_orders')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('No authenticated user found');
        throw Exception('يجب تسجيل الدخول لتحديث حالة الطلب');
      }

      developer.log('Updating order status for orderId: $orderId to $newStatus');

      // جلب بيانات الطلب للحصول على user_id
      final orderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('farmer_orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        developer.log('Order $orderId does not exist in farmer_orders');
        throw Exception('الطلب غير موجود');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final userId = orderData['user_id'] as String?;

      if (userId == null) {
        developer.log('user_id not found in order $orderId');
        throw Exception('معرف المشتري غير متوفر');
      }

      developer.log('Found user_id: $userId for order $orderId');

      // تحديث الحالة في farmer_orders
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('farmer_orders')
          .doc(orderId)
          .update({'status': newStatus});
      developer.log('Successfully updated status in farmer_orders for order $orderId');

      // تحديث الحالة في orders الخاص بالمشتري
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
      developer.log('Successfully updated status in orders for order $orderId');
    } catch (e) {
      developer.log('Error updating order status for order $orderId: $e', error: e);
      throw Exception('فشل تحديث حالة الطلب: $e');
    }
  }
}