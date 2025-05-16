import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/core/services/product_service.dart';
import 'package:hadaer_blady/features/add_product/data/product_model.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/offer_carousel.dart';

part 'my_coop_state.dart';

class MyCoopCubit extends Cubit<MyCoopState> {
  final FirebaseAuthService _authService;
  final ProductService _productService;
  final CustomProductService _customProductService;

  MyCoopCubit({
    required FirebaseAuthService authService,
    required ProductService productService,
    required CustomProductService customProductService,
  }) : _authService = authService,
       _productService = productService,
       _customProductService = customProductService,
       super(MyCoopInitial());

  /// Initialize and load user data
  Future<void> initialize() async {
    emit(MyCoopLoading());
    try {
      final currentUser = _authService.getCurrentUser();

      if (currentUser == null || currentUser.uid.isEmpty) {
        emit(MyCoopUnauthenticated());
        return;
      }

      final userData = await _authService.getCurrentUserData();
      final currentUserEmail = currentUser.email;
      final userId = currentUser.uid;

      final isCoopOwner = userData['job_title'] == 'صاحب حظيرة';
      final isAdmin = currentUserEmail == 'ahmed.roma22@gmail.com';

      if (!isCoopOwner && !isAdmin) {
        emit(MyCoopAccessDenied());
        return;
      }

      emit(
        MyCoopUserData(
          userData: userData,
          isCoopOwner: isCoopOwner,
          isAdmin: isAdmin,
          userId: userId,
          isRegularProductsLoading: true,
          isSpecialOffersLoading: true,
        ),
      );

      // Load products after state is emitted
      loadRegularProducts(userId);
      loadSpecialOffers(userId);
    } catch (e) {
      log('Error initializing MyCoopCubit: $e');
      emit(MyCoopError('حدث خطأ أثناء تحميل البيانات: $e'));
    }
  }

  /// Load regular products for the farmer
  Future<void> loadRegularProducts(String userId) async {
    try {
      if (state is MyCoopUserData) {
        final currentState = state as MyCoopUserData;
        emit(
          currentState.copyWith(
            isRegularProductsLoading: true,
            regularProductsError: null,
          ),
        );

        final products = await _productService.getProductsByFarmer(userId);
        log('Loaded ${products.length} regular products');

        emit(
          (state as MyCoopUserData).copyWith(
            regularProducts: products,
            isRegularProductsLoading: false,
          ),
        );
      }
    } catch (e) {
      log('Error loading regular products: $e');
      if (state is MyCoopUserData) {
        emit(
          (state as MyCoopUserData).copyWith(
            isRegularProductsLoading: false,
            regularProductsError: 'حدث خطأ أثناء تحميل المنتجات: $e',
          ),
        );
      }
    }
  }

  /// Load special offers for the farmer
  Future<void> loadSpecialOffers(String userId) async {
    try {
      if (state is MyCoopUserData) {
        final currentState = state as MyCoopUserData;
        emit(
          currentState.copyWith(
            isSpecialOffersLoading: true,
            specialOffersError: null,
          ),
        );

        final offers = await _customProductService.getProductsByFarmer(userId);
        log('Loaded ${offers.length} special offers');

        emit(
          (state as MyCoopUserData).copyWith(
            specialOffers: offers,
            isSpecialOffersLoading: false,
          ),
        );
      }
    } catch (e) {
      log('Error loading special offers: $e');
      if (state is MyCoopUserData) {
        emit(
          (state as MyCoopUserData).copyWith(
            isSpecialOffersLoading: false,
            specialOffersError: 'حدث خطأ أثناء تحميل العروض الخاصة: $e',
          ),
        );
      }
    }
  }

  /// Delete a product (regular or special offer)
  Future<void> deleteProduct(String productId, bool isSpecialOffer) async {
    try {
      if (isSpecialOffer) {
        await _customProductService.deleteProduct(productId);
        // Reload special offers
        if (state is MyCoopUserData) {
          final userId = (state as MyCoopUserData).userId;
          loadSpecialOffers(userId);
        }
      } else {
        await _productService.deleteProduct(productId);
        // Reload regular products
        if (state is MyCoopUserData) {
          final userId = (state as MyCoopUserData).userId;
          loadRegularProducts(userId);
        }
      }
    } catch (e) {
      log('Error deleting ${isSpecialOffer ? "special offer" : "product"}: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  /// Convert ProductModel to CustomProduct with safe field handling
  CustomProduct convertToCustomProduct(ProductModel product, String userId) {
    final productMap = product.toMap();
    log('Converting to CustomProduct: $productMap');

    return CustomProduct(
      id: product.id,
      title: _getStringValue(productMap, ['name', 'title'], 'غير معروف'),
      description: _getStringValue(productMap, ['description'], ''),
      price: _getDoubleValue(productMap, ['price'], 0.0),
      displayLocation: _getStringValue(productMap, [
        'display_location',
        'city',
      ], 'غير محدد'),
      imageUrl: _getStringValue(productMap, ['image_url', 'image'], ''),
      farmerId: userId,
      createdAt:
          productMap['created_at'] is Timestamp
              ? (productMap['created_at'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  /// Safely retrieves string value from map with fallback
  String _getStringValue(
    Map<String, dynamic> map,
    List<String> keys,
    String defaultValue,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return defaultValue;
  }

  /// Safely retrieves double value from map with conversion
  double _getDoubleValue(
    Map<String, dynamic> map,
    List<String> keys,
    double defaultValue,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) {
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? defaultValue;
      }
    }
    return defaultValue;
  }
}
