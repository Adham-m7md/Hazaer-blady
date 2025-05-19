// core/managers/deep_link_manager.dart
import 'dart:async';
import 'dart:developer';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/dialog_utiles.dart';
import 'package:hadaer_blady/core/utils/snack_bar_utiles.dart';
import '../services/get_it.dart';
import '../services/firebase_auth_service.dart';
import '../services/custom_product_servise.dart';
import '../../features/add_custom_product/presentation/custom_product_screen_details.dart';

class DeepLinkManager {
  final GlobalKey<NavigatorState> _navigatorKey;
  late AppLinks _appLinks;
  late FirebaseAuthService _authService;
  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkManager(this._navigatorKey) {
    _authService = getIt<FirebaseAuthService>();
    _appLinks = AppLinks();
  }

  Future<void> initialize() async {
    await _handleInitialLink();
    _listenForLinks();
  }

  Future<void> _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        await _handleDeepLink(uri);
      }
    } catch (e) {
      log('Error handling initial deep link: $e');
    }
  }

  void _listenForLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) => _handleDeepLink(uri),
      onError: (err) => log('Error in uriLinkStream: $err'),
    );
  }

  Future<void> _handleDeepLink(Uri uri) async {
    log('Handling deep link: $uri');
    
    if (!_isValidProductLink(uri)) {
      log('Invalid deep link format: $uri');
      return;
    }

    final productId = uri.queryParameters['product_id'];
    if (productId == null) {
      log('No product_id found in deep link');
      return;
    }

    await _navigateToProduct(productId);
  }

  bool _isValidProductLink(Uri uri) {
    return uri.scheme == DeepLinkConfig.scheme && 
           uri.host == DeepLinkConfig.productHost;
  }

  Future<void> _navigateToProduct(String productId) async {
    if (!_authService.isUserLoggedIn()) {
      log('User not logged in, showing login dialog for deep link');
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
        log('Product not found for deep link ID: $productId');
        SnackBarUtils.showError(_navigatorKey, 'المنتج غير موجود');
      }
    } catch (e) {
      log('Error handling deep link navigation: $e');
      SnackBarUtils.showError(_navigatorKey, 'حدث خطأ أثناء تحميل المنتج');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}

class DeepLinkConfig {
  static const scheme = 'hadaerblady';
  static const productHost = 'product';
}