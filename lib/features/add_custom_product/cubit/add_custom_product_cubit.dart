import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/services/custom_product_servise.dart';
import 'package:hadaer_blady/features/add_custom_product/cubit/add_custom_product_state.dart';
import 'package:image_picker/image_picker.dart';

class AddCustomProductCubit extends Cubit<AddCustomProductState> {
  AddCustomProductCubit() : super(AddCustomProductInitial());

  final CustomProductService _productService = CustomProductService();
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final locationController = TextEditingController();

  File? selectedImage;

  @override
  Future<void> close() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    locationController.dispose();
    return super.close();
  }

  Future<void> pickImage(BuildContext context) async {
    try {
      log('Starting image picking process');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        log('No image selected');
        return;
      }

      final File imageFile = File(image.path);
      final imageSizeInMB = imageFile.lengthSync() / (1024 * 1024);
      log('Selected image size: $imageSizeInMB MB');

      if (imageSizeInMB > 5) {
        emit(
          AddCustomProductImageError(
            errorMessage: 'حجم الصورة يجب ألا يتجاوز 5 ميجابايت',
          ),
        );
        return;
      }

      selectedImage = imageFile;
      emit(AddCustomProductInitial());
      log('Image selected successfully');
    } catch (e) {
      log('Error picking image: $e');
      emit(
        AddCustomProductImageError(errorMessage: 'حدث خطأ أثناء اختيار الصورة'),
      );
    }
  }

  Future<void> submitProduct(BuildContext context) async {
    try {
      log('Starting product submission process');
      if (formKey.currentState?.validate() != true) {
        log('Form validation failed');
        emit(
          AddCustomProductFailure(
            errorMessage: 'يرجى ملء جميع الحقول بشكل صحيح',
          ),
        );
        return;
      }

      if (selectedImage == null) {
        log('No image selected');
        emit(
          AddCustomProductImageError(errorMessage: 'يرجى اختيار صورة للمنتج'),
        );
        return;
      }

      emit(AddCustomProductLoading());
      log('Form validated, proceeding to parse price');

      final double price;
      try {
        price = double.parse(priceController.text.trim());
        if (price <= 0) {
          log('Invalid price: $price');
          emit(
            AddCustomProductFailure(
              errorMessage: 'السعر يجب أن يكون أكبر من صفر',
            ),
          );
          return;
        }
      } catch (e) {
        log('Price parsing error: $e');
        emit(AddCustomProductFailure(errorMessage: 'يرجى إدخال سعر صحيح'));
        return;
      }

      log('Submitting product to CustomProductService');
      final String productId = await _productService.addProduct(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price: price,
        displayLocation: locationController.text.trim(),
        image: selectedImage!,
      );

      log('Product submitted successfully with ID: $productId');
      emit(AddCustomProductSuccess(productId: productId));

      // Clear form after successful submission
      titleController.clear();
      descriptionController.clear();
      priceController.clear();
      locationController.clear();
      selectedImage = null;
    } on CustomException catch (e) {
      log('CustomException during submission: ${e.message}');
      emit(AddCustomProductFailure(errorMessage: e.message));
    } catch (e) {
      log('Unexpected error during submission: $e');
      emit(
        AddCustomProductFailure(
          errorMessage: 'حدث خطأ غير متوقع أثناء إضافة المنتج',
        ),
      );
    }
  }
}
