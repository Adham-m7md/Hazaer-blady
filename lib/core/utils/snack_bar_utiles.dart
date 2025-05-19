import 'package:flutter/material.dart';
class SnackBarUtils {
  static void showError(GlobalKey<NavigatorState> navigatorKey, String message) {
    _showSnackBar(navigatorKey, message, Colors.red);
  }

  static void showSuccess(GlobalKey<NavigatorState> navigatorKey, String message) {
    _showSnackBar(navigatorKey, message, Colors.green);
  }

  static void showInfo(GlobalKey<NavigatorState> navigatorKey, String message) {
    _showSnackBar(navigatorKey, message, Colors.blue);
  }

  static void _showSnackBar(
    GlobalKey<NavigatorState> navigatorKey, 
    String message, 
    Color backgroundColor,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}