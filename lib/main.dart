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
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/features/splash/splash_screen.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';
import 'package:hadaer_blady/firebase_options.dart';
import 'package:hadaer_blady/generated/l10n.dart';
import 'package:app_links/app_links.dart';
import 'core/services/custom_product_servise.dart';
import 'core/services/shared_prefs_singleton.dart';
import 'features/add_custom_product/presentation/custom_product_screen_details.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('Background message received: ${message.data}');
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
  if (!Platform.isIOS) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  late FirebaseAuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = getIt<FirebaseAuthService>();
    WidgetsBinding.instance.addObserver(this);
    setupInteractedMessage();
    initAppLinks();
  }

  Future<void> setupInteractedMessage() async {
    await initialize();
    await FirebaseMessaging.instance.subscribeToTopic("offers");

    // Handle notification when app is opened from terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle notification when app is in background and opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        display(message);
      }
    });
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    log('Handling message: ${message.data}');
    if (message.notification != null) {
      Map<String, dynamic> data = message.data;
      String? productId = data['productId'];
      
      if (productId != null && productId.isNotEmpty) {
        // التحقق من تسجيل الدخول أولاً
        if (!_authService.isUserLoggedIn()) {
          log('User not logged in, redirecting to login screen');
          _showLoginRequiredDialog();
          return;
        }

        final productService = getIt<CustomProductService>();
        final product = await productService.getProductById(productId);
        log('Fetched product: $product');
        
        if (product != null) {
          widget.navigatorKey.currentState?.pushNamed(
            CustomProductDetailScreen.id,
            arguments: product,
          );
        } else {
          log('Product not found for ID: $productId');
          _showSnackBar('المنتج غير موجود');
        }
      } else {
        log('No productId found in notification data: $data');
      }
    }
  }

  void _showLoginRequiredDialog() {
    final context = widget.navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('تسجيل الدخول مطلوب'),
          content: const Text('يجب تسجيل الدخول أولاً لعرض تفاصيل المنتج'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.navigatorKey.currentState?.pushNamed(SigninScreen.id);
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    final context = widget.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> initAppLinks() async {
    _appLinks = AppLinks();

    // Handle initial deep link
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      log('Error handling initial deep link: $e');
    }

    // Handle deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      log('Error in uriLinkStream: $err');
    });
  }

  void _handleDeepLink(Uri uri) async {
    log('Handling deep link: $uri');
    if (uri.scheme == 'hadaerblady' && uri.host == 'product') {
      final productId = uri.queryParameters['product_id'];
      
      if (productId != null) {
        // التحقق من تسجيل الدخول أولاً
        if (!_authService.isUserLoggedIn()) {
          log('User not logged in, redirecting to login screen for deep link');
          _showLoginRequiredDialog();
          return;
        }

        final productService = getIt<CustomProductService>();
        final product = await productService.getProductById(productId);
        
        if (product != null) {
          widget.navigatorKey.currentState?.pushNamed(
            CustomProductDetailScreen.id,
            arguments: product,
          );
        } else {
          log('Product not found for deep link ID: $productId');
          _showSnackBar('المنتج غير موجود');
        }
      }
    }
  }

  Future<void> initialize() async {
    AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'offer_channel',
      'عروض مميزة',
      description: 'إشعارات للعروض الجديدة المميزة',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInitializationSettings = DarwinInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await FlutterLocalNotificationsPlugin().initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          String? productId = data['productId'];
          
          if (productId != null) {
            // التحقق من تسجيل الدخول أولاً
            if (!_authService.isUserLoggedIn()) {
              log('User not logged in, redirecting to login screen from local notification');
              _showLoginRequiredDialog();
              return;
            }

            final productService = getIt<CustomProductService>();
            final product = await productService.getProductById(productId);
            
            if (product != null) {
              widget.navigatorKey.currentState?.pushNamed(
                CustomProductDetailScreen.id,
                arguments: product,
              );
            } else {
              log('Product not found for notification ID: $productId');
              _showSnackBar('المنتج غير موجود');
            }
          }
        }
      },
    );

    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
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
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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