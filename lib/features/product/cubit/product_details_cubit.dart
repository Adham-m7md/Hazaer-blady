import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/firebase_auth_service.dart';
import 'package:hadaer_blady/features/product/cubit/product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit(this._firebaseAuthService)
    : super(const ProductDetailsState.initial());

  final FirebaseAuthService _firebaseAuthService;
  static const int _quantityStep = 50;

  Future<void> fetchProductData(
    String productId,
    Map<String, dynamic> initialProduct,
  ) async {
    emit(
      state.copyWith(
        status: ProductDetailsStatus.loading,
        productData: initialProduct,
      ),
    );

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        emit(
          state.copyWith(
            status: ProductDetailsStatus.error,
            errorMessage: 'لا يوجد اتصال بالإنترنت',
          ),
        );
        return;
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

      if (snapshot.exists) {
        emit(
          state.copyWith(
            status: ProductDetailsStatus.loaded,
            productData: snapshot.data() as Map<String, dynamic>,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ProductDetailsStatus.error,
            errorMessage: 'المنتج غير موجود',
          ),
        );
      }
    } catch (e) {
      log('Error fetching product data: $e');
      emit(
        state.copyWith(
          status: ProductDetailsStatus.error,
          errorMessage: 'خطأ في جلب بيانات المنتج: $e',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> fetchFarmerData(String farmerId) async {
    try {
      final farmerData = await _firebaseAuthService.getFarmerById(farmerId);
      return farmerData.isNotEmpty
          ? farmerData
          : {'name': 'حظيرة غير معروفة', 'city': 'غير محدد'};
    } catch (e) {
      log('Error fetching farmer data: $e');
      return {'name': 'حظيرة غير معروفة', 'city': 'غير محدد'};
    }
  }

  Future<bool> isFarmer() async {
    try {
      final userData = await _firebaseAuthService.getCurrentUserData();
      return userData['job_title'] == 'صاحب حظيرة';
    } catch (e) {
      log('Error checking farmer status: $e');
      return false;
    }
  }

  void incrementQuantity() {
    emit(state.copyWith(quantity: state.quantity + _quantityStep));
  }

  void decrementQuantity() {
    if (state.quantity > _quantityStep) {
      emit(state.copyWith(quantity: state.quantity - _quantityStep));
    }
  }
}
