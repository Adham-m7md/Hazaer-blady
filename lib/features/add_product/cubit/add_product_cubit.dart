import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/services/product_service.dart';
import 'package:image_picker/image_picker.dart';

part 'add_product_state.dart';

class AddProductCubit extends Cubit<AddProductState> {
  final ProductService _productService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AddProductCubit(this._productService)
    : _auth = FirebaseAuth.instance,
      _firestore = FirebaseFirestore.instance,
      super(AddProductState());

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        emit(state.copyWith(image: File(pickedFile.path), errorMessage: null));
      }
    } catch (e) {
      log('Error picking image: $e');
      emit(state.copyWith(errorMessage: 'فشل في اختيار الصورة'));
    }
  }

  void updateMinWeight(int minWeight) =>
      emit(state.copyWith(minWeight: minWeight));
  void updateMaxWeight(int maxWeight) =>
      emit(state.copyWith(maxWeight: maxWeight));

  Future<bool> _isBarnOwner() async {
    final user = _auth.currentUser;
    if (user == null) {
      log('No authenticated user found');
      return false;
    }
    log('Checking user document for UID: ${user.uid}');
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    log('User document data: $userData');
    return userData != null && userData['job_title'] == 'صاحب حظيرة';
  }

  Future<void> addProduct() async {
    if (!_validateForm()) return;

    if (!await _isBarnOwner()) {
      emit(
        state.copyWith(
          errorMessage: 'ليس لديك صلاحية إضافة منتج. يجب أن تكون صاحب حظيرة.',
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = _auth.currentUser!;
      log('Adding product for user: ${user.uid}');
      final pricePerKg = double.parse(state.priceController.text.trim());

      await _productService.addProduct(
        name: state.nameController.text.trim(),
        description: state.descriptionController.text.trim(),
        pricePerKg: pricePerKg,
        image: state.image!,
        minWeight: state.minWeight,
        maxWeight: state.maxWeight,
      );
      log('Product added successfully');
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } on CustomException catch (e) {
      log('CustomException in addProduct: ${e.message}');
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      log('Unexpected error in addProduct: $e');
      emit(state.copyWith(isLoading: false, errorMessage: 'خطأ غير متوقع: $e'));
    }
  }

  bool _validateForm() {
    if (state.nameController.text.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'الرجاء إدخال اسم المنتج'));
      return false;
    }
    if (state.descriptionController.text.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'الرجاء إدخال وصف المنتج'));
      return false;
    }
    final priceText = state.priceController.text.trim();
    if (priceText.isEmpty ||
        double.tryParse(priceText) == null ||
        double.parse(priceText) <= 0) {
      emit(state.copyWith(errorMessage: 'الرجاء إدخال سعر صحيح'));
      return false;
    }
    if (state.image == null) {
      emit(state.copyWith(errorMessage: 'الرجاء اختيار صورة للمنتج'));
      return false;
    }
    if (state.minWeight > state.maxWeight) {
      emit(
        state.copyWith(
          errorMessage: 'الوزن الأدنى يجب أن يكون أقل من أو يساوي الأقصى',
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Future<void> close() {
    state.dispose();
    return super.close();
  }
}
