import 'package:flutter/material.dart';

import '../../features/auth/presentation/signin/view/signin_screen.dart';

class DialogUtils {
  static void showLoginRequired(GlobalKey<NavigatorState> navigatorKey) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('تسجيل الدخول مطلوب'),
            content: const Text('يجب تسجيل الدخول أولاً لعرض تفاصيل المنتج'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  navigatorKey.currentState?.pushNamed(SigninScreen.id);
                },
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
    );
  }

  static void showError(
    GlobalKey<NavigatorState> navigatorKey,
    String message,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('خطأ'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('موافق'),
              ),
            ],
          ),
    );
  }

  static void showSuccess(
    GlobalKey<NavigatorState> navigatorKey,
    String message,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('نجح'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('موافق'),
              ),
            ],
          ),
    );
  }
}
