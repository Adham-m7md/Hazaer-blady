import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hadaer_blady/core/notfications/deep_link_maneger.dart';
import 'package:hadaer_blady/core/notfications/firebase_maneger.dart';
import 'package:hadaer_blady/core/notfications/notfication_maneger.dart';
import 'package:hadaer_blady/core/services/get_it.dart';
import 'package:hadaer_blady/core/services/on_generate_route.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/features/splash/splash_screen.dart';
import 'package:hadaer_blady/firebase_options.dart';
import 'package:hadaer_blady/generated/l10n.dart';

import 'core/services/shared_prefs_singleton.dart';

Future<void> main() async {
  await AppInitializer.initialize();
  runApp(const MyApp());
}

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Prefs.init();
    await FirebaseManager.initialize();
    setupGetIt();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late NotificationManager _notificationManager;
  late DeepLinkManager _deepLinkManager;

  @override
  void initState() {
    super.initState();
    _initializeManagers();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeManagers() {
    _notificationManager = NotificationManager(_navigatorKey);
    _deepLinkManager = DeepLinkManager(_navigatorKey);

    _notificationManager.initialize();
    _deepLinkManager.initialize();
  }

  @override
  void dispose() {
    _notificationManager.dispose();
    _deepLinkManager.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizationConfig.delegates,
      supportedLocales: AppLocalizationConfig.supportedLocales,
      locale: AppLocalizationConfig.defaultLocale,
      theme: AppThemeConfig.theme,
      onGenerateRoute: onGenerateRoute,
      initialRoute: SplashScreen.id,
    );
  }
}

class AppLocalizationConfig {
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static List<Locale> get supportedLocales => S.delegate.supportedLocales;
  static const Locale defaultLocale = Locale('ar');
}

class AppThemeConfig {
  static ThemeData get theme => ThemeData(
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.kprimaryColor,
      primary: AppColors.kprimaryColor,
    ),
    useMaterial3: true,
  );
}
