/* import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// معالج رسائل الإشعارات في الخلفية - يجب أن تكون خارج الكلاس
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // تأكد من تهيئة Firebase قبل معالجة الرسائل الخلفية
  await Firebase.initializeApp();
  log('Received background message: ${message.messageId}');

  // لا يمكن استدعاء FlutterLocalNotificationsPlugin هنا للإصدارات الأحدث من Flutter
  // يمكن فقط تسجيل استلام الرسالة وسيتم معالجتها عند فتح التطبيق
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // مفتاح التنقل العام - للانتقال إلى الشاشات المناسبة عند النقر على الإشعار
  late final GlobalKey<NavigatorState> navigatorKey;

  // تعريف قناة الإشعارات للأندرويد
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'offer_channel',
        'عروض مميزة',
        description: 'إشعارات للعروض الجديدة المميزة',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

  // وظيفة لتقوم بإعادة معالج للإشعارات عند النقر عليها
  Function(Map<String, dynamic> data)? _onNotificationTap;

  // تعيين معالج النقر على الإشعار
  void setNotificationTapHandler(Function(Map<String, dynamic> data) handler) {
    _onNotificationTap = handler;
  }

  // تهيئة خدمة الإشعارات مع تمرير مفتاح التنقل
  Future<void> initialize({required GlobalKey<NavigatorState> navKey}) async {
    try {
      navigatorKey = navKey;

      // طلب إذن الإشعارات
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      log('User granted permission: ${settings.authorizationStatus}');

      // الحصول على رمز الجهاز (FCM token)
      String? token = await _messaging.getToken();
      if (token != null) {
        log('FCM Token: $token');
        // حفظ رمز الجهاز في Firestore للمستخدم الحالي (إذا كان لديك نظام مستخدمين)
        // يمكنك إضافة كود هنا لحفظ الرمز مرتبطاً بالمستخدم الحالي
      }

      // تهيئة الإشعارات المحلية
      await _initializeLocalNotifications();

      // الاستماع للإشعارات في حالة التطبيق مفتوح
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Received foreground message: ${message.messageId}');
        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });

      // تعيين معالج الإشعارات في الخلفية
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // معالجة الإشعارات عند فتح التطبيق من حالة مغلقة
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        log(
          'App opened from terminated state with message: ${initialMessage.messageId}',
        );
        _handleMessage(initialMessage);
      }

      // معالجة الإشعارات عند فتح التطبيق من حالة الخلفية
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('App opened from background with message: ${message.messageId}');
        _handleMessage(message);
      });

      // الاشتراك في موضوع العروض
      await subscribeToOffersTopic();
      log('Notification service initialized successfully');
    } catch (e) {
      log('Error initializing NotificationService: $e');
    }
  }

  // تهيئة الإشعارات المحلية
  Future<void> _initializeLocalNotifications() async {
    // تهيئة إعدادات الأندرويد
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // تهيئة إعدادات آيفون
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // دمج الإعدادات
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // تهيئة plugin الإشعارات المحلية
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Notification tapped: ${response.payload}');
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            // استدعاء معالج النقر إذا كان متاحاً
            if (_onNotificationTap != null) {
              _onNotificationTap!(data);
            } else {
              _handleNotificationTap(data);
            }
          } catch (e) {
            log('Error parsing notification payload: $e');
          }
        }
      },
    );

    // إنشاء قناة إشعارات للأندرويد
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // إعداد تفاصيل إشعارات آيفون (اختياري للتخصيص)
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // عرض إشعار محلي
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // إعداد تفاصيل الإشعار حسب النظام
      final NotificationDetails platformDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: const Color(0xFF2196F3), // لون الإشعار - يمكن تغييره
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            message.notification?.body ?? 'تم إضافة عرض جديد',
            htmlFormatBigText: true,
            contentTitle: message.notification?.title ?? 'عرض جديد',
            htmlFormatContentTitle: true,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // عرض الإشعار
      await _localNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? 'عرض جديد',
        message.notification?.body ?? 'تم إضافة عرض جديد',
        platformDetails,
        payload: jsonEncode(message.data),
      );
      log('Local notification shown: ${message.messageId}');
    } catch (e) {
      log('Error showing local notification: $e');
    }
  }

  // إرسال إشعار العرض إلى جميع المستخدمين
  Future<void> sendOfferNotification({
    required String productId,
    required String title,
    required String description,
    required double price,
  }) async {
    // نقل مفتاح FCM إلى متغيرات بيئية أو ملف تكوين آمن
    const String serverKey =
        'YOUR_FCM_SERVER_KEY_HERE'; // استبدل بالمفتاح الخاص بك
    const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    // إعداد محتوى الإشعار
    final body = {
      'to': '/topics/offers', // إرسال لكل المشتركين في موضوع "العروض"
      'notification': {
        'title': 'عرض جديد: $title',
        'body': description,
        'sound': 'default',
      },
      'data': {
        'productId': productId,
        'title': title,
        'price': price.toString(),
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'type': 'offer',
      },
      'priority': 'high',
    };

    try {
      // تخزين الإشعار في Firestore
      await _firestore.collection('notifications').doc(productId).set({
        'productId': productId,
        'title': title,
        'description': description,
        'price': price,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'offer',
      });
      log('Notification stored in Firestore for product ID: $productId');

      // إرسال الإشعار عبر FCM
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        log('FCM notification sent successfully: ${response.body}');

        // التحقق من نجاح الإرسال
        if (responseData['failure'] > 0) {
          log(
            'Warning: Some devices failed to receive notification: ${responseData['results']}',
          );
        }
      } else {
        log(
          'Failed to send FCM notification: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to send FCM notification: ${response.body}');
      }
    } catch (e) {
      log('Error sending notification: $e');
      rethrow;
    }
  }

  // الاشتراك في موضوع العروض
  Future<void> subscribeToOffersTopic() async {
    try {
      await _messaging.subscribeToTopic('offers');
      log('Subscribed to offers topic');
    } catch (e) {
      log('Error subscribing to offers topic: $e');
      throw Exception('Failed to subscribe to offers topic: $e');
    }
  }

  // إلغاء الاشتراك من موضوع العروض
  Future<void> unsubscribeFromOffersTopic() async {
    try {
      await _messaging.unsubscribeFromTopic('offers');
      log('Unsubscribed from offers topic');
    } catch (e) {
      log('Error unsubscribing from offers topic: $e');
      throw Exception('Failed to unsubscribe from offers topic: $e');
    }
  }

  // تحديث رمز الجهاز
  Future<String?> refreshToken() async {
    String? token = await _messaging.getToken();
    log('FCM Token refreshed: $token');
    return token;
  }

  // معالجة الرسالة عند استلامها
  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('productId') && data.containsKey('type')) {
      log(
        'Handling notification with productId: ${data['productId']} and type: ${data['type']}',
      );

      // تحديث حالة القراءة في Firestore إذا كان الإشعار من نوع عرض
      if (data['type'] == 'offer') {
        _firestore
            .collection('notifications')
            .doc(data['productId'])
            .update({'isRead': true})
            .then((_) {
              log('Notification marked as read in Firestore');
            })
            .catchError((e) {
              log('Error marking notification as read: $e');
            });
      }

      // استدعاء معالج النقر إذا كان متاحاً
      if (_onNotificationTap != null) {
        _onNotificationTap!(data);
      } else {
        _handleNotificationTap(data);
      }
    }
  }

  // معالجة النقر على الإشعار
  void _handleNotificationTap(Map<String, dynamic> data) {
    log('Notification tapped with data: $data');
    // يمكن تنفيذ منطق التنقل هنا أو ترك المعالجة لمن يستدعي هذه الخدمة
  }

  // تعليم جميع الإشعارات كمقروءة
  Future<void> markAllNotificationsAsRead() async {
    try {
      final notifications = await _firestore.collection('notifications').get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      log('All notifications marked as read successfully');
      return;
    } catch (e) {
      log('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // الحصول على عدد الإشعارات غير المقروءة
  Future<int?> getUnreadNotificationsCount() async {
    try {
      final unreadSnapshot =
          await _firestore
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .count()
              .get();

      return unreadSnapshot.count;
    } catch (e) {
      log('Error getting unread notifications count: $e');
      return 0;
    }
  }
}
 */