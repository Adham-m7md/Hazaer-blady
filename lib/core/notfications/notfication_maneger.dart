// core/managers/notification_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hadaer_blady/core/utils/dialog_utiles.dart';
import 'package:hadaer_blady/core/utils/snack_bar_utiles.dart';

import '../../features/add_custom_product/presentation/custom_product_screen_details.dart';
import '../services/custom_product_servise.dart';
import '../services/firebase_auth_service.dart';
import '../services/get_it.dart';

class NotificationManager {
  final GlobalKey<NavigatorState> _navigatorKey;
  late FirebaseAuthService _authService;
  late FlutterLocalNotificationsPlugin _localNotifications;

  NotificationManager(this._navigatorKey) {
    _authService = getIt<FirebaseAuthService>();
    _localNotifications = FlutterLocalNotificationsPlugin();
  }

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _setupFirebaseMessaging();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      NotificationConfig.channelId,
      NotificationConfig.channelName,
      description: NotificationConfig.channelDescription,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _setupFirebaseMessaging() async {
    await FirebaseMessaging.instance.subscribeToTopic("offers");

    // Handle initial message (from terminated state)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _handleFirebaseMessage(initialMessage);
    }

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleFirebaseMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _displayLocalNotification(message);
    }
  }

  Future<void> _handleFirebaseMessage(RemoteMessage message) async {
    log('Handling firebase message: ${message.data}');

    if (message.notification == null) return;

    final productId = message.data['productId'];
    if (productId == null || productId.isEmpty) {
      log('No productId found in notification data');
      return;
    }

    await _navigateToProduct(productId);
  }

  Future<void> _handleLocalNotificationTap(
    NotificationResponse response,
  ) async {
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!);
      final productId = data['productId'];

      if (productId != null) {
        log('Handling local notification tap for product: $productId');
        await _navigateToProduct(productId);
      }
    } catch (e) {
      log('Error parsing notification payload: $e');
    }
  }

  Future<void> _navigateToProduct(String productId) async {
    if (!_authService.isUserLoggedIn()) {
      log('User not logged in, showing login dialog');
      DialogUtils.showLoginRequired(_navigatorKey);
      return;
    }

    try {
      final productService = getIt<CustomProductService>();
      final product = await productService.getProductById(productId);

      if (product != null) {
        _navigatorKey.currentState?.pushNamed(
          CustomProductDetailScreen.id,
          arguments: product,
        );
      } else {
        log('Product not found for ID: $productId');
        SnackBarUtils.showError(_navigatorKey, 'المنتج غير موجود');
      }
    } catch (e) {
      log('Error fetching product: $e');
      SnackBarUtils.showError(_navigatorKey, 'حدث خطأ أثناء تحميل المنتج');
    }
  }

  Future<void> _displayLocalNotification(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final notificationDetails = _buildNotificationDetails(message);

      await _localNotifications.show(
        id,
        message.notification?.title,
        message.notification?.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      log("Error displaying notification: $e");
    }
  }

  NotificationDetails _buildNotificationDetails(RemoteMessage message) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationConfig.channelId,
        NotificationConfig.channelName,
        channelDescription: NotificationConfig.channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF2196F3),
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
  }

  void dispose() {}
}

class NotificationConfig {
  static const channelId = 'offer_channel';
  static const channelName = 'عروض مميزة';
  static const channelDescription = 'إشعارات للعروض الجديدة المميزة';
}
