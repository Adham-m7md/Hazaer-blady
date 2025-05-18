import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/on_generate_route.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/features/splash/splash_screen.dart';
import 'package:hadaer_blady/firebase_options.dart';
import 'package:hadaer_blady/generated/l10n.dart';
import 'core/services/custom_product_servise.dart';
import 'core/services/shared_prefs_singleton.dart';
import 'features/add_custom_product/presentation/custom_product_screen_details.dart';

Future<void> _firebaseMessagingBackGroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Prefs.init();
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: true,
    sound: true,
  );
  if (Platform.isIOS == false) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackGroundHandler);
  }
  setupGetIt();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  Future<void> setupInteractedMessage(BuildContext context) async {
    initialize(context);
    await FirebaseMessaging.instance.subscribeToTopic("offers");
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {}

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        display(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message.notification != null) {
        final GlobalKey<NavigatorState> navigatorKey =
            GlobalKey<NavigatorState>();
        Map<String, dynamic> data = message.data;
        String? productId = data['productId'];

        final productService = getIt<CustomProductService>();
        final product = await productService.getProductById(productId ?? '');

        if (product != null) {
          navigatorKey.currentState?.pushNamed(
            CustomProductDetailScreen.id,
            arguments: product,
          );
        }
      }
    });
  }

  Future<void> initialize(BuildContext context) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'offer_channel',
      'عروض مميزة',
      description: 'إشعارات للعروض الجديدة المميزة',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    var iosInitializationSettings = const DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    await FlutterLocalNotificationsPlugin().initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) async {},
    );

    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "offer_channel",
          "عروض مميزة",
          channelDescription: 'إشعارات للعروض الجديدة المميزة',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: Color(0xFF2196F3),
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            message.notification?.body ?? 'تم إضافة عرض جديد',
            htmlFormatBigText: true,
            contentTitle: message.notification?.title ?? 'عرض جديد',
            htmlFormatContentTitle: true,
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      await FlutterLocalNotificationsPlugin().show(
        id,
        message.notification?.title,
        message.notification?.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } on Exception catch (e) {
      log("Error displaying Notification: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    setupInteractedMessage(context);
    return MaterialApp(
      navigatorKey: widget.navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('ar'),
      theme: ThemeData(
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.kprimaryColor,
          primary: AppColors.kprimaryColor,
        ),
        useMaterial3: true,
      ),
      onGenerateRoute: onGenerateRoute,
      initialRoute: SplashScreen.id,
    );
  }
}
