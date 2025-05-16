import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/features/add_product/data/product_model.dart';
import 'package:hadaer_blady/features/home/presentation/widgets/custom_offers_list/offer_carousel.dart';

class CustomProductService {
  static const _maxImageSizeMB = 5;
  static const _adminEmail = 'ahmed.roma22@gmail.com';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  CustomProductService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<String> addProduct({
    required String title,
    required String description,
    required double price,
    required String displayLocation,
    required File image,
  }) async {
    try {
      log('Starting addProduct for user: ${_auth.currentUser?.uid}');
      _validateUser();
      _validateInputs(title, description, price, displayLocation, image);

      final imageUrl = await _uploadImage(image);

      final offerRef = await _firestore.collection('offers').add({
        'title': title.trim(),
        'description': description.trim(),
        'price': price,
        'display_location': displayLocation.trim(),
        'image_url': imageUrl,
        'farmer_id': _auth.currentUser!.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      log('Offer added successfully with ID: ${offerRef.id}');
      try {
        /*  final notificationService = getIt<NotificationService>();
        await notificationService.sendOfferNotification(
          productId: offerRef.id,
          title: title,
          description: description,
          price: price,
        ); */

        /*     final callable = FirebaseFunctions.instance.httpsCallable(
          'sendOfferNotification',
        );
       await callable.call({
  'productId': offerRef.id,
  'title': title,
  'description': description,
  'price': price.toString(),
});
 */
      } catch (e) {
        log('Error sending notification: $e');
      }

      return offerRef.id;
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error: ${e.code} - ${e.message}');
      throw CustomException(
        message: e.message ?? 'Authentication error while adding product',
      );
    } on FirebaseException catch (e) {
      log('Firebase error: ${e.code} - ${e.message}');
      throw CustomException(
        message: e.message ?? 'Error adding product to database',
      );
    } catch (e) {
      log('Unexpected error: $e');
      throw CustomException(message: 'Unexpected error while adding product');
    }
  }

  Future<CustomProduct?> getProductById(String productId) async {
    try {
      if (productId.isEmpty) {
        log('Empty productId provided');
        throw CustomException(message: 'معرف المنتج فارغ');
      }
      final doc = await _firestore.collection('offers').doc(productId).get();
      if (!doc.exists) {
        log('Product not found for ID: $productId');
        return null;
      }
      log('Product fetched: ${doc.data()}');
      return CustomProduct.fromMap(doc.data()!, doc.id);
    } catch (e) {
      log('Error fetching product: $e');
      throw CustomException(message: 'فشل في جلب المنتج: $e');
    }
  }

  Future<List<ProductModel>> getProductsByFarmer(String farmerId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('offers')
              .where('farmer_id', isEqualTo: farmerId)
              .get();

      final products =
          querySnapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList();

      log('Retrieved ${products.length} products for farmer: $farmerId');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase error: ${e.code} - ${e.message}');
      throw CustomException(message: e.message ?? 'Error retrieving products');
    } catch (e) {
      log('Unexpected error: $e');
      throw CustomException(message: 'Unexpected error retrieving products');
    }
  }

  Future<List<CustomProduct>> getAllProducts() async {
    try {
      log('Fetching all products from Firestore');
      final querySnapshot = await _firestore.collection('offers').get();

      final products =
          querySnapshot.docs
              .map((doc) => CustomProduct.fromMap(doc.data(), doc.id))
              .toList();

      log('Retrieved ${products.length} products');
      return products;
    } on FirebaseException catch (e) {
      log('Firebase error: ${e.code} - ${e.message}');
      throw CustomException(message: e.message ?? 'Error retrieving products');
    } catch (e) {
      log('Unexpected error: $e');
      throw CustomException(message: 'Unexpected error retrieving products');
    }
  }

  Future<void> updateProduct({
    required String productId,
    String? title,
    String? description,
    double? price,
    String? displayLocation,
    File? image,
  }) async {
    try {
      _validateUser();

      final offerDoc =
          await _firestore.collection('offers').doc(productId).get();
      if (!offerDoc.exists) {
        throw CustomException(message: 'Product not found');
      }
      if (offerDoc.data()?['farmer_id'] != _auth.currentUser!.uid) {
        throw CustomException(message: 'Unauthorized to edit this product');
      }

      final updateData = <String, dynamic>{};
      if (title != null && title.trim().isNotEmpty) {
        updateData['title'] = title.trim();
      }
      if (description != null && description.trim().isNotEmpty) {
        updateData['description'] = description.trim();
      }
      if (price != null && price > 0) {
        updateData['price'] = price;
      }
      if (displayLocation != null && displayLocation.trim().isNotEmpty) {
        updateData['display_location'] = displayLocation.trim();
      }
      if (image != null) {
        updateData['image_url'] = await _uploadImage(image);
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('offers').doc(productId).update(updateData);
        log('Product updated successfully: $productId');
      } else {
        log('No changes provided for product: $productId');
      }
    } on FirebaseException catch (e) {
      log('Firebase error: ${e.code} - ${e.message}');
      throw CustomException(message: e.message ?? 'Error updating product');
    } catch (e) {
      log('Unexpected error: $e');
      throw CustomException(message: 'Unexpected error updating product');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      _validateUser();

      final offerDoc =
          await _firestore.collection('offers').doc(productId).get();
      if (!offerDoc.exists) {
        throw CustomException(message: 'Product not found');
      }
      if (offerDoc.data()?['farmer_id'] != _auth.currentUser!.uid) {
        throw CustomException(message: 'Unauthorized to delete this product');
      }

      // Delete the product image if exists
      final imageUrl = offerDoc.data()?['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
          log('Product image deleted: $imageUrl');
        } catch (e) {
          log('Error deleting image: $e');
        }
      }

      // Delete related notifications from the notifications collection
      try {
        final notificationsQuerySnapshot =
            await _firestore
                .collection('notifications')
                .where('productId', isEqualTo: productId)
                .get();

        final batch = _firestore.batch();

        // Add all notification deletions to batch
        for (final doc in notificationsQuerySnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Execute the batch
        await batch.commit();
        log(
          'Deleted ${notificationsQuerySnapshot.docs.length} related notifications for product: $productId',
        );
      } catch (e) {
        log('Error deleting related notifications: $e');
        // Continue with product deletion even if notification deletion fails
      }

      // Delete the product itself
      await _firestore.collection('offers').doc(productId).delete();
      log('Product deleted successfully: $productId');
    } on FirebaseException catch (e) {
      log('Firebase error: ${e.code} - ${e.message}');
      throw CustomException(message: e.message ?? 'Error deleting product');
    } catch (e) {
      log('Unexpected error: $e');
      throw CustomException(message: 'Unexpected error deleting product');
    }
  }

  Future<Map<String, dynamic>> getFarmerData(String farmerId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(farmerId).get();
      if (!userDoc.exists) {
        throw CustomException(message: 'Farmer not found');
      }

      final userData = userDoc.data()!;
      userData['uid'] = userDoc.id;
      log('Farmer data retrieved: $farmerId');
      return userData;
    } on FirebaseException catch (e) {
      log('Firebase error: ${e.code} - ${e.message}');
      throw CustomException(
        message: e.message ?? 'Error retrieving farmer data',
      );
    } catch (e) {
      log('Unexpected error: $e');
      throw CustomException(message: 'Unexpected error retrieving farmer data');
    }
  }

  void _validateUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw CustomException(message: 'User not authenticated');
    }
    if (user.email != _adminEmail) {
      throw CustomException(message: 'Unauthorized: Admin access required');
    }
  }

  void _validateInputs(
    String title,
    String description,
    double price,
    String displayLocation,
    File image,
  ) {
    if (title.trim().isEmpty) {
      throw CustomException(message: 'Title is required');
    }
    if (description.trim().isEmpty) {
      throw CustomException(message: 'Description is required');
    }
    if (price <= 0) {
      throw CustomException(message: 'Price must be greater than zero');
    }
    if (displayLocation.trim().isEmpty) {
      throw CustomException(message: 'Display location is required');
    }
    final imageSizeInMB = image.lengthSync() / (1024 * 1024);
    if (imageSizeInMB > _maxImageSizeMB) {
      throw CustomException(
        message: 'Image size must not exceed $_maxImageSizeMB MB',
      );
    }
  }

  Future<String> _uploadImage(File image) async {
    final storageRef = _storage.ref().child(
      'offer_images/${_auth.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final uploadTask = await storageRef.putFile(image);
    final imageUrl = await uploadTask.ref.getDownloadURL();
    log('Image uploaded: $imageUrl');
    return imageUrl;
  }
}
