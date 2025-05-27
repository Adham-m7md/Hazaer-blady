// core/services/notification_service.dart
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // الحصول على جميع الإشعارات للمستخدم الحالي
  Stream<QuerySnapshot> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل دخول');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // تحديث حالة الإشعار إلى "مقروء"
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      log('Error marking notification as read: $e');
    }
  }

  // تحديث جميع الإشعارات إلى "مقروءة"
  Future<void> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      log('Error marking all notifications as read: $e');
    }
  }

  // الحصول على عدد الإشعارات غير المقروءة
  Future<int> getUnreadNotificationsCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      log('Error getting unread notifications count: $e');
      return 0;
    }
  }

  // حذف إشعار معين
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      log('Error deleting notification: $e');
    }
  }

  // حذف جميع الإشعارات المقروءة
  Future<void> deleteReadNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: true)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      log('Error deleting read notifications: $e');
    }
  }

  // إنشاء إشعار محلي (داخل التطبيق)
  Future<void> createLocalNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'data': data ?? {},
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      log('Error creating local notification: $e');
    }
  }

  // الاشتراك في topic معين للإشعارات
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      log('Subscribed to topic: $topic');
    } catch (e) {
      log('Error subscribing to topic $topic: $e');
    }
  }

  // إلغاء الاشتراك في topic معين
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic');
    } catch (e) {
      log('Error unsubscribing from topic $topic: $e');
    }
  }

  // تحديث FCM token
  Future<void> updateFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
        
        log('FCM Token updated: $token');
      }
    } catch (e) {
      log('Error updating FCM token: $e');
    }
  }

  // الحصول على تفاصيل الإشعار
  Future<Map<String, dynamic>?> getNotificationDetails(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      log('Error getting notification details: $e');
      return null;
    }
  }

  // فلترة الإشعارات حسب النوع
  Stream<QuerySnapshot> getNotificationsByType(String type) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل دخول');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // إحصائيات الإشعارات
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final allNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      final unreadNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final offerNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'offer')
          .get();

      final orderNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'farmer_order')
          .get();

      final statusNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'order_status_update')
          .get();

      return {
        'total': allNotifications.docs.length,
        'unread': unreadNotifications.docs.length,
        'offers': offerNotifications.docs.length,
        'orders': orderNotifications.docs.length,
        'status_updates': statusNotifications.docs.length,
      };
    } catch (e) {
      log('Error getting notification stats: $e');
      return {};
    }
  }
}