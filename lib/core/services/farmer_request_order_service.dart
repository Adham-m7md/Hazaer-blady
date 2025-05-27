import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FarmerOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // الحصول على طلبات المزارع
  Stream<QuerySnapshot> getFarmerOrders() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل دخول');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('farmer_orders')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // تحديث حالة الطلب
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      log('Updating order status for orderId: $orderId to $newStatus');

      // أولاً، الحصول على بيانات الطلب من farmer_orders للحصول على user_id
      final farmerOrderDoc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('farmer_orders')
              .doc(orderId)
              .get();

      if (!farmerOrderDoc.exists) {
        throw Exception('الطلب غير موجود في طلبات المزارع');
      }

      final farmerOrderData = farmerOrderDoc.data() as Map<String, dynamic>;
      final userId = farmerOrderData['user_id'] as String?;

      if (userId == null) {
        throw Exception('لم يتم العثور على معرف المستخدم في الطلب');
      }

      log('Found user_id: $userId for order $orderId');

      // إنشاء batch operation لتحديث كلا المكانين
      final batch = _firestore.batch();

      // تحديث حالة الطلب في farmer_orders
      final farmerOrderRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('farmer_orders')
          .doc(orderId);

      batch.update(farmerOrderRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });

      log('Successfully updated status in farmer_orders for order $orderId');

      // تحديث حالة الطلب في orders للمستخدم
      final userOrderRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId);

      batch.update(userOrderRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });

      log('Preparing to update user order for order $orderId');

      // تنفيذ العملية
      await batch.commit();

      log('Successfully updated status in both collections for order $orderId');
    } catch (e) {
      log('Error updating order status for order $orderId: $e');
      throw Exception('فشل تحديث حالة الطلب: $e');
    }
  }

  // الحصول على تفاصيل طلب معين
  Future<DocumentSnapshot?> getOrderDetails(String orderId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      final doc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('farmer_orders')
              .doc(orderId)
              .get();

      return doc.exists ? doc : null;
    } catch (e) {
      log('Error getting order details: $e');
      return null;
    }
  }

  // احصائيات الطلبات
  Future<Map<String, int>> getOrderStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      final ordersSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('farmer_orders')
              .get();

      final orders = ordersSnapshot.docs;

      int pending = 0;
      int confirmed = 0;
      int completed = 0;
      int cancelled = 0;

      for (var order in orders) {
        final data = order.data();
        final status = data['status'] as String? ?? 'pending';

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'confirmed':
            confirmed++;
            break;
          case 'completed':
            completed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      return {
        'total': orders.length,
        'pending': pending,
        'confirmed': confirmed,
        'completed': completed,
        'cancelled': cancelled,
      };
    } catch (e) {
      log('Error getting order stats: $e');
      return {};
    }
  }

  // فلترة الطلبات حسب الحالة
  Stream<QuerySnapshot> getOrdersByStatus(String status) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل دخول');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('farmer_orders')
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // الحصول على الطلبات الجديدة (غير المؤكدة)
  Stream<QuerySnapshot> getNewOrders() {
    return getOrdersByStatus('pending');
  }

  // تأكيد طلب
  Future<void> confirmOrder(String orderId) async {
    await updateOrderStatus(orderId, 'confirmed');
  }

  // إلغاء طلب
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, 'cancelled');
  }

  // إتمام طلب
  Future<void> completeOrder(String orderId) async {
    await updateOrderStatus(orderId, 'completed');
  }
}
