import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';

class UserDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// حذف المستخدم وجميع البيانات المرتبطة به
  Future<void> deleteUserWithAllData({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw CustomException(message: 'لم يتم تسجيل الدخول');
    }

    final userId = user.uid;
    log('بدء عملية حذف المستخدم: $userId');

    try {
      // 1. حذف المنتجات
      await _deleteAllUserProducts(userId);

      // 2. حذف العروض
      await deleteAllCustomProducts();

      // 3. حذف ملفات التخزين
      await _deleteAllUserStorageFiles(userId);

      // 4. حذف بيانات Firestore
      await _deleteAllUserCollections(userId);

      // 5. إعادة المصادقة وحذف الحساب
      await _reauthenticateAndDeleteAccount(user, password);

      log('تم حذف المستخدم وبياناته بنجاح: $userId');
    } on FirebaseAuthException catch (e) {
      log('خطأ في المصادقة: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        throw CustomException(message: 'يرجى إعادة تسجيل الدخول لحذف الحساب');
      } else if (e.code == 'wrong-password') {
        throw CustomException(message: 'كلمة المرور غير صحيحة');
      }
      throw CustomException(message: e.message ?? 'حدث خطأ أثناء حذف الحساب');
    } catch (e, stackTrace) {
      log('خطأ غير متوقع أثناء حذف الحساب: $e\nStackTrace: $stackTrace');
      throw CustomException(message: 'حدث خطأ أثناء حذف الحساب');
    }
  }

  /// حذف جميع المنتجات الخاصة بالمستخدم
  Future<void> _deleteAllUserProducts(String userId) async {
    log('بدء حذف منتجات المستخدم: $userId');
    try {
      final querySnapshot =
          await _firestore
              .collection('products')
              .where('farmer_id', isEqualTo: userId)
              .get();

      if (querySnapshot.docs.isEmpty) {
        log('لا توجد منتجات للحذف');
        return;
      }

      log('تم العثور على ${querySnapshot.docs.length} منتج');
      final batch = _firestore.batch();
      final imagesToDelete = <String>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final imageUrl = data['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          imagesToDelete.add(imageUrl);
        }
        batch.delete(doc.reference);
      }

      await batch.commit();
      log('تم حذف المنتجات بنجاح');

      await _deleteStorageImages(imagesToDelete);
    } catch (e) {
      log('خطأ أثناء حذف المنتجات: $e');
    }
  }

  /// حذف جميع ملفات التخزين الخاصة بالمستخدم
  Future<void> _deleteAllUserStorageFiles(String userId) async {
    log('بدء حذف ملفات التخزين: $userId');
    final storagePaths = [
      'product_images/$userId',
      'profile_images/$userId',
      'offer_images/$userId',
    ];

    for (final path in storagePaths) {
      try {
        final storageRef = _storage.ref().child(path);
        final listResult = await storageRef.listAll();
        final deleteTasks = <Future<void>>[];

        for (final item in listResult.items) {
          deleteTasks.add(
            item
                .delete()
                .then((_) {
                  log('تم حذف الملف: ${item.fullPath}');
                })
                .catchError((e) {
                  log('خطأ في حذف الملف ${item.fullPath}: $e');
                }),
          );
        }

        for (final prefix in listResult.prefixes) {
          final subListResult = await prefix.listAll();
          for (final item in subListResult.items) {
            deleteTasks.add(
              item
                  .delete()
                  .then((_) {
                    log('تم حذف الملف الفرعي: ${item.fullPath}');
                  })
                  .catchError((e) {
                    log('خطأ في حذف الملف الفرعي ${item.fullPath}: $e');
                  }),
            );
          }
        }

        await Future.wait(deleteTasks);
        log('تم حذف جميع الملفات من $path بنجاح');
      } catch (e) {
        log('خطأ أثناء حذف الملفات من $path: $e');
      }
    }
  }

  /// حذف جميع بيانات المستخدم من Firestore
  Future<void> _deleteAllUserCollections(String userId) async {
    log('بدء حذف بيانات Firestore: $userId');

    // المجموعات الأساسية
    final collections = ['users', 'orders', 'notifications', 'user_settings'];

    // حذف الوثائق الأساسية
    final deleteTasks = <Future<void>>[];
    for (final collection in collections) {
      deleteTasks.add(
        _firestore
            .collection(collection)
            .doc(userId)
            .delete()
            .then((_) {
              log('تم حذف وثيقة من $collection');
            })
            .catchError((e) {
              log('خطأ في حذف وثيقة من $collection: $e');
            }),
      );
    }

    // المجموعات المرتبطة بحقل user_id
    final relatedCollections = [
      {'collection': 'orders', 'field': 'user_id'},
      {'collection': 'reviews', 'field': 'user_id'},
    ];

    for (final item in relatedCollections) {
      try {
        final querySnapshot =
            await _firestore
                .collection(item['collection']!)
                .where(item['field']!, isEqualTo: userId)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in querySnapshot.docs) {
            batch.delete(doc.reference);
          }
          deleteTasks.add(
            batch
                .commit()
                .then((_) {
                  log(
                    'تم حذف ${querySnapshot.docs.length} وثيقة من ${item['collection']}',
                  );
                })
                .catchError((e) {
                  log('خطأ في حذف وثائق من ${item['collection']}: $e');
                }),
          );
        }
      } catch (e) {
        log('خطأ أثناء معالجة ${item['collection']}: $e');
      }
    }

    await Future.wait(deleteTasks);
    log('تم حذف جميع بيانات Firestore بنجاح');
  }

  /// إعادة المصادقة وحذف الحساب
  Future<void> _reauthenticateAndDeleteAccount(
    User user,
    String password,
  ) async {
    log('بدء إعادة المصادقة: ${user.uid}');
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      log('تم إعادة المصادقة بنجاح');
      await user.delete();
      log('تم حذف الحساب بنجاح');
    } catch (e) {
      log('خطأ أثناء إعادة المصادقة أو حذف الحساب: $e');
      rethrow;
    }
  }

  /// حذف الصور من التخزين
  Future<void> _deleteStorageImages(List<String> imageUrls) async {
    final deleteTasks = <Future<void>>[];
    for (final imageUrl in imageUrls) {
      deleteTasks.add(
        _storage
            .refFromURL(imageUrl)
            .delete()
            .then((_) {
              log('تم حذف الصورة: $imageUrl');
            })
            .catchError((e) {
              log('خطأ في حذف الصورة $imageUrl: $e');
            }),
      );
    }
    await Future.wait(deleteTasks);
  }

  /// حذف جميع العروض الخاصة بالمستخدم
  Future<void> deleteAllCustomProducts() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw CustomException(message: 'لم يتم تسجيل الدخول');
    }

    log('بدء حذف العروض: ${user.uid}');
    try {
      // التحقق مما إذا كان المستخدم لديه أذونات حذف العروض
      if (user.email != 'ahmed.roma22@gmail.com') {
        log(
          'المستخدم ${user.uid} ليس لديه أذونات لحذف العروض بسبب قيود الأمان',
        );
        return;
      }

      final querySnapshot =
          await _firestore
              .collection('offers')
              .where('farmer_id', isEqualTo: user.uid)
              .get();

      if (querySnapshot.docs.isEmpty) {
        log('لا توجد عروض للحذف');
        return;
      }

      log('تم العثور على ${querySnapshot.docs.length} عرض');
      final batch = _firestore.batch();
      final imagesToDelete = <String>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final imageUrl = data['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          imagesToDelete.add(imageUrl);
        }
        batch.delete(doc.reference);
      }

      try {
        await batch.commit();
        log('تم حذف جميع العروض بنجاح');
      } catch (e) {
        log('فشل حذف العروض: $e');
      }

      await _deleteStorageImages(imagesToDelete);
      log('اكتمل حذف العروض والصور بنجاح');
    } catch (e) {
      log('خطأ أثناء حذف العروض: $e');
    }
  }
}
