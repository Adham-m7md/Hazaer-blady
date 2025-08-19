import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/features/add_product/data/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> addProduct({
    required String name,
    required String description,
    required double pricePerKg,
    required File image,
    // required int minWeight,
    // required int maxWeight,
  }) async {
    try {
      log('Starting addProduct for user: ${_auth.currentUser?.uid}');
      final user = _auth.currentUser;
      if (user == null) {
        throw CustomException(message: 'لم يتم تسجيل الدخول');
      }

      log('Fetching user document for UID: ${user.uid}');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      log('User document data: $userData');
      if (userData == null || userData['job_title'] != 'صاحب حظيرة') {
        throw CustomException(message: 'ليس لديك صلاحية إضافة منتج');
      }

      if (name.trim().isEmpty) {
        throw CustomException(message: 'اسم المنتج مطلوب');
      }
      if (description.trim().isEmpty) {
        throw CustomException(message: 'وصف المنتج مطلوب');
      }
      if (pricePerKg <= 0) {
        throw CustomException(message: 'السعر يجب أن يكون أكبر من صفر');
      }
      log('Validating image size');
      final imageSizeInMB = image.lengthSync() / (1024 * 1024);
      if (imageSizeInMB > 5) {
        throw CustomException(message: 'حجم الصورة يجب ألا يتجاوز 5 ميجابايت');
      }

      log('Uploading image to Storage');
      final storageRef = _storage.ref().child(
        'product_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final uploadTask = await storageRef.putFile(image);
      final imageUrl = await uploadTask.ref.getDownloadURL();
      log('Image uploaded successfully: $imageUrl');

      log('Adding product to Firestore');
      final productRef = await _firestore.collection('products').add({
        'id': '', // سيتم تحديثه لاحقًا
        'name': name.trim(),
        'description': description.trim(),
        'price_per_kg': pricePerKg,
        'image_url': imageUrl,
        'farmer_id': user.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      // تحديث المستند بمعرف المستند
      await productRef.update({'id': productRef.id});
      log(
        'Product added successfully with ID: ${productRef.id} for user: ${user.uid}',
      );
      return productRef.id;
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error adding product: ${e.code} - ${e.message}');
      throw CustomException(
        message: e.message ?? 'خطأ في المصادقة أثناء إضافة المنتج',
      );
    } on FirebaseException catch (e) {
      log('Firebase error adding product: ${e.code} - ${e.message}');
      throw CustomException(message: e.message ?? 'حدث خطأ أثناء إضافة المنتج');
    } catch (e) {
      log('Unexpected error adding product: $e');
      throw CustomException(message: 'حدث خطأ غير متوقع أثناء إضافة المنتج');
    }
  }

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final querySnapshot = await _firestore.collection('products').get();

      final products =
          querySnapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList();

      log('Retrieved ${products.length} products');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase error fetching all products: ${e.message}');
      throw CustomException(
        message: e.message ?? 'حدث خطأ أثناء استرجاع المنتجات',
      );
    } catch (e) {
      log('Unexpected error fetching all products: $e');
      throw CustomException(message: 'حدث خطأ أثناء استرجاع المنتجات');
    }
  }

  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? pricePerKg,
    File? image,
    
    double? quantity, // Added quantity
    double? totalPrice, // Added totalPrice
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw CustomException(message: 'لم يتم تسجيل الدخول');
      }

      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        throw CustomException(message: 'المنتج غير موجود');
      }
      if (productDoc.data()?['farmer_id'] != user.uid) {
        throw CustomException(message: 'ليس لديك صلاحية تعديل هذا المنتج');
      }

      final updateData = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        updateData['name'] = name.trim();
      }
      if (description != null && description.trim().isNotEmpty) {
        updateData['description'] = description.trim();
      }
      if (pricePerKg != null && pricePerKg > 0) {
        updateData['price_per_kg'] = pricePerKg;
      }
      if (quantity != null && quantity > 0) {
        updateData['quantity'] = quantity;
      }
      if (totalPrice != null && totalPrice > 0) {
        updateData['total_price'] = totalPrice;
      }

      // Update image if provided
      if (image != null) {
        final storageRef = _storage.ref().child(
          'product_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final uploadTask = await storageRef.putFile(image);
        final imageUrl = await uploadTask.ref.getDownloadURL();
        updateData['image_url'] = imageUrl;
      }

      // Update the product in Firestore
      if (updateData.isNotEmpty) {
        await _firestore
            .collection('products')
            .doc(productId)
            .update(updateData);
        log('Product updated successfully: $productId');
      } else {
        log('No changes provided for product: $productId');
      }
    } on FirebaseException catch (e) {
      log('Firebase error updating product: ${e.message}');
      throw CustomException(message: e.message ?? 'حدث خطأ أثناء تحديث المنتج');
    } catch (e) {
      log('Unexpected error updating product: $e');
      throw CustomException(message: 'حدث خطأ أثناء تحديث المنتج');
    }
  }

  Future<List<ProductModel>> getProductsByFarmer(String farmerId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('products')
              .where('farmer_id', isEqualTo: farmerId)
              .get();
      final products =
          querySnapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList();
      log('Retrieved ${products.length} products for farmer: $farmerId');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase error fetching products: ${e.message}');
      throw CustomException(
        message: e.message ?? 'حدث خطأ أثناء استرجاع المنتجات',
      );
    } catch (e) {
      log('Unexpected error fetching products: $e');
      throw CustomException(message: 'حدث خطأ أثناء استرجاع المنتجات');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw CustomException(message: 'لم يتم تسجيل الدخول');
      }

      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        throw CustomException(message: 'المنتج غير موجود');
      }
      if (productDoc.data()?['farmer_id'] != user.uid) {
        throw CustomException(message: 'ليس لديك صلاحية حذف هذا المنتج');
      }

      final imageUrl = productDoc.data()?['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final storageRef = _storage.refFromURL(imageUrl);
          await storageRef.delete();
          log('Product image deleted from storage: $imageUrl');
        } catch (e) {
          log('Error deleting product image: $e');
        }
      }

      // Delete the product from Firestore
      await _firestore.collection('products').doc(productId).delete();
      log('Product deleted successfully: $productId');
    } on FirebaseException catch (e) {
      log('Firebase error deleting product: ${e.message}');
      throw CustomException(message: e.message ?? 'حدث خطأ أثناء حذف المنتج');
    } catch (e) {
      log('Unexpected error deleting product: $e');
      throw CustomException(message: 'حدث خطأ أثناء حذف المنتج');
    }
  }

  Future<Map<String, dynamic>> getFarmerData(String farmerId) async {
    try {
      log('Fetching farmer data for farmerId: $farmerId');
      final userDoc = await _firestore.collection('users').doc(farmerId).get();
      if (!userDoc.exists) {
        throw CustomException(message: 'صاحب الحظيرة غير موجود');
      }
      final userData = userDoc.data()!;
      userData['uid'] = userDoc.id;
      log('Farmer data retrieved: $userData');
      return userData;
    } on FirebaseException catch (e) {
      log('Firebase error fetching farmer data: ${e.message}');
      throw CustomException(
        message: e.message ?? 'حدث خطأ أثناء جلب بيانات صاحب الحظيرة',
      );
    } catch (e) {
      log('Unexpected error fetching farmer data: $e');
      throw CustomException(message: 'حدث خطأ أثناء جلب بيانات صاحب الحظيرة');
    }
  }

  Future<void> deleteAllProducts() async {
    try {
      // التحقق من تسجيل دخول المستخدم
      final user = _auth.currentUser;
      if (user == null) {
        throw CustomException(message: 'لم يتم تسجيل الدخول');
      }

      log('بدء عملية حذف جميع المنتجات للمستخدم: ${user.uid}');

      // الحصول على جميع المنتجات الخاصة بالمستخدم الحالي
      final querySnapshot =
          await _firestore
              .collection('products')
              .where('farmer_id', isEqualTo: user.uid)
              .get();

      log('تم العثور على ${querySnapshot.docs.length} منتج للحذف');

      if (querySnapshot.docs.isEmpty) {
        log('لا توجد منتجات للحذف');
        return;
      }

      // إنشاء مجموعة عمليات الحذف
      final batch = _firestore.batch();
      final imagesToDelete = <String>[];

      // إضافة كل منتج للحذف وتجميع روابط الصور
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final imageUrl = data['image_url'] as String?;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          imagesToDelete.add(imageUrl);
        }

        batch.delete(doc.reference);
      }

      // تنفيذ عملية الحذف الجماعي
      await batch.commit();
      log('تم حذف جميع المنتجات بنجاح');

      // حذف الصور من التخزين
      for (final imageUrl in imagesToDelete) {
        try {
          final storageRef = _storage.refFromURL(imageUrl);
          await storageRef.delete();
          log('تم حذف صورة المنتج من التخزين: $imageUrl');
        } catch (e) {
          log('خطأ في حذف صورة المنتج: $e');
          // نستمر في العملية حتى لو فشل حذف بعض الصور
        }
      }

      log('اكتملت عملية حذف جميع المنتجات والصور بنجاح');
    } on FirebaseException catch (e) {
      log('خطأ Firebase أثناء حذف المنتجات: ${e.message}');
      throw CustomException(message: e.message ?? 'حدث خطأ أثناء حذف المنتجات');
    } catch (e) {
      log('خطأ غير متوقع أثناء حذف المنتجات: $e');
      throw CustomException(message: 'حدث خطأ أثناء حذف جميع المنتجات');
    }
  }
}
