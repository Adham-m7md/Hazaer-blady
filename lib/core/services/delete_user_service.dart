import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hadaer_blady/core/errors/exeptions.dart';
import 'package:hadaer_blady/core/services/shared_prefs_singleton.dart';

class EnhancedUserDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // إعدادات المهلة الزمنية
  static const Duration _operationTimeout = Duration(seconds: 30);
  static const int _batchSize = 500; // حجم الـ batch للعمليات الكبيرة

  /// حذف المستخدم وجميع البيانات المرتبطة به
  Future<void> deleteUserWithAllData({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw CustomException(message: 'لم يتم تسجيل الدخول');
    }

    final userId = user.uid;
    final userEmail = user.email;
    log('بدء عملية حذف المستخدم: $userId');

    try {
      // التحقق من الاتصال بالإنترنت أولاً
      await _checkConnectivity();

      // 1. حذف الـ SubCollections الخاصة بالمستخدم أولاً (قبل حذف الوثيقة الرئيسية)
      await _deleteAllUserSubCollections(userId);

      // 2. حذف المنتجات والعروض (الأهم لأن فيها صور)
      await _deleteAllUserProducts(userId);
      await _deleteAllUserOffers(userId);

      // 3. حذف الطلبات من جميع المستخدمين (كمشتري أو بائع)
      await _deleteAllUserOrders(userId);

      // 4. حذف التقييمات (المكتوبة والمستلمة)
      await _deleteAllUserRatings(userId);

      // 5. حذف البيانات الشخصية والإشعارات
      await _deleteUserPersonalData(userId, userEmail);

      // 6. حذف ملفات التخزين
      await _deleteAllUserStorageFiles(userId);

      // 7. حذف وثيقة المستخدم الرئيسية (بعد حذف كل الباقي)
      await _deleteMainUserDocument(userId);

      // 8. مسح SharedPreferences
      await _clearSharedPreferences();

      // 9. إعادة المصادقة وحذف الحساب (آخر خطوة)
      await _reauthenticateAndDeleteAccount(user, password);

      log('تم حذف المستخدم وبياناته بنجاح: $userId');
    } on FirebaseAuthException catch (e) {
      log('خطأ في المصادقة: ${e.code} - ${e.message}');
      _handleAuthException(e);
    } catch (e, stackTrace) {
      log('خطأ غير متوقع أثناء حذف الحساب: $e\nStackTrace: $stackTrace');
      throw CustomException(
        message: 'حدث خطأ أثناء حذف الحساب: ${e.toString()}',
      );
    }
  }

  /// حذف جميع الـ SubCollections الخاصة بالمستخدم (محسنة)
  Future<void> _deleteAllUserSubCollections(String userId) async {
    log('بدء حذف SubCollections: $userId');

    try {
      final userDocRef = _firestore.collection('users').doc(userId);

      // التأكد من أن الوثيقة موجودة
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        log('وثيقة المستخدم غير موجودة، تخطي حذف SubCollections');
        return;
      }

      final subCollections = [
        'orders',
        'reviews',
        'farmer_orders',
        'location',
        'cart',
      ];

      // حذف كل subcollection بشكل منفصل وآمن
      for (final subCollection in subCollections) {
        await _deleteEntireSubcollectionSafely(userDocRef, subCollection);
      }

      log('تم حذف جميع SubCollections بنجاح');
    } catch (e) {
      log('خطأ أثناء حذف SubCollections: $e');
      // نكمل العملية حتى لو فشل حذف subcollection معين
    }
  }

  /// حذف subcollection بالكامل بطريقة آمنة
  Future<void> _deleteEntireSubcollectionSafely(
    DocumentReference userDocRef,
    String subcollectionName,
  ) async {
    try {
      log('بدء حذف subcollection: $subcollectionName');
      final subcollectionRef = userDocRef.collection(subcollectionName);

      // التحقق من وجود وثائق في الـ subcollection
      final initialSnapshot = await subcollectionRef.limit(1).get();
      if (initialSnapshot.docs.isEmpty) {
        log('$subcollectionName فارغة، تم التخطي');
        return;
      }

      int totalDeleted = 0;
      bool hasMore = true;
      int attempts = 0;
      const maxAttempts = 10; // حد أقصى للمحاولات لتجنب اللوب اللانهائي

      while (hasMore && attempts < maxAttempts) {
        attempts++;

        try {
          final snapshot = await subcollectionRef
              .limit(_batchSize)
              .get()
              .timeout(_operationTimeout);

          if (snapshot.docs.isEmpty) {
            hasMore = false;
            break;
          }

          // إنشاء batch للحذف
          final batch = _firestore.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }

          // تنفيذ الـ batch
          await batch.commit().timeout(_operationTimeout);

          totalDeleted += snapshot.docs.length;
          log(
            'تم حذف ${snapshot.docs.length} وثيقة من $subcollectionName (المجموع: $totalDeleted)',
          );

          // إذا كان عدد الوثائق أقل من الحد الأقصى، فهذا يعني أنها آخر مجموعة
          if (snapshot.docs.length < _batchSize) {
            hasMore = false;
          }

          // استراحة قصيرة بين الـ batches
          if (hasMore) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        } catch (e) {
          log('خطأ في المحاولة $attempts لحذف $subcollectionName: $e');
          if (attempts >= maxAttempts) {
            rethrow;
          }
          // استراحة أطول في حالة الخطأ
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      log(
        'تم الانتهاء من حذف $subcollectionName - المجموع: $totalDeleted وثيقة',
      );
    } catch (e) {
      log('خطأ نهائي في حذف subcollection $subcollectionName: $e');
      // لا نرمي الخطأ هنا عشان نكمل حذف باقي الـ subcollections
    }
  }

  /// حذف جميع الطلبات المرتبطة بالمستخدم (محسنة)
  Future<void> _deleteAllUserOrders(String userId) async {
    log('بدء حذف الطلبات المرتبطة بالمستخدم: $userId');

    try {
      // الحصول على قائمة بجميع المستخدمين
      final usersSnapshot = await _firestore
          .collection('users')
          .get()
          .timeout(_operationTimeout);

      final deleteTasks = <Future<void>>[];

      for (final userDoc in usersSnapshot.docs) {
        final currentUserId = userDoc.id;

        // تخطي المستخدم الحالي لأن subcollections بتاعته هتتمسح في مكان تاني
        if (currentUserId == userId) continue;

        // حذف الطلبات من subcollection orders
        deleteTasks.add(
          _deleteOrdersFromSubcollection(currentUserId, 'orders', userId),
        );

        // حذف الطلبات من subcollection farmer_orders
        deleteTasks.add(
          _deleteOrdersFromSubcollection(
            currentUserId,
            'farmer_orders',
            userId,
          ),
        );
      }

      // تنفيذ جميع المهام بالتوازي
      await Future.wait(deleteTasks);
      log('تم حذف جميع الطلبات المرتبطة بالمستخدم بنجاح');
    } catch (e) {
      log('خطأ أثناء حذف الطلبات: $e');
    }
  }

  /// التحقق من الاتصال بالإنترنت
  Future<void> _checkConnectivity() async {
    try {
      await _firestore
          .collection('users')
          .limit(1)
          .get()
          .timeout(_operationTimeout);
    } catch (e) {
      throw CustomException(
        message: 'لا يوجد اتصال بالإنترنت أو مشكلة في الخادم',
      );
    }
  }

  /// معالجة أخطاء المصادقة
  void _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'requires-recent-login':
        throw CustomException(message: 'يرجى إعادة تسجيل الدخول لحذف الحساب');
      case 'wrong-password':
        throw CustomException(message: 'كلمة المرور غير صحيحة');
      case 'user-disabled':
        throw CustomException(message: 'تم تعطيل هذا الحساب');
      case 'user-not-found':
        throw CustomException(message: 'المستخدم غير موجود');
      case 'too-many-requests':
        throw CustomException(
          message: 'تم تجاوز الحد المسموح من المحاولات، حاول لاحقاً',
        );
      default:
        throw CustomException(message: e.message ?? 'حدث خطأ أثناء حذف الحساب');
    }
  }

  /// حذف جميع المنتجات الخاصة بالمستخدم
  Future<void> _deleteAllUserProducts(String userId) async {
    log('بدء حذف منتجات المستخدم: $userId');
    try {
      await _deleteDocumentsByField(
        'products',
        'farmer_id',
        userId,
        hasImages: true,
      );
      log('تم حذف المنتجات بنجاح');
    } catch (e) {
      log('خطأ أثناء حذف المنتجات: $e');
    }
  }

  /// حذف جميع العروض الخاصة بالمستخدم
  Future<void> _deleteAllUserOffers(String userId) async {
    log('بدء حذف العروض: $userId');
    try {
      await _deleteDocumentsByField(
        'offers',
        'farmer_id',
        userId,
        hasImages: true,
      );
      log('تم حذف العروض بنجاح');
    } catch (e) {
      log('خطأ أثناء حذف العروض: $e');
    }
  }

  /// حذف الطلبات من subcollection معين
  Future<void> _deleteOrdersFromSubcollection(
    String userDocId,
    String subcollection,
    String targetUserId,
  ) async {
    try {
      final subcollectionRef = _firestore
          .collection('users')
          .doc(userDocId)
          .collection(subcollection);

      // البحث عن الطلبات المرتبطة بالمستخدم المستهدف
      final queries = [
        subcollectionRef.where('user_id', isEqualTo: targetUserId),
        subcollectionRef.where('farmer_id', isEqualTo: targetUserId),
      ];

      for (final query in queries) {
        final snapshot = await query.get().timeout(_operationTimeout);
        if (snapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit().timeout(_operationTimeout);
          log(
            'تم حذف ${snapshot.docs.length} طلب من $subcollection للمستخدم $userDocId',
          );
        }
      }
    } catch (e) {
      log('خطأ في حذف الطلبات من $subcollection للمستخدم $userDocId: $e');
    }
  }

  /// حذف جميع التقييمات المرتبطة بالمستخدم
  Future<void> _deleteAllUserRatings(String userId) async {
    log('بدء حذف التقييمات للمستخدم: $userId');

    try {
      // حذف التقييمات المستلمة (في subcollection reviews)
      await _deleteSubcollectionFromAllUsers(
        'reviews',
        'rater_user_id',
        userId,
      );

      // حذف التقييمات من المجموعة القديمة إن وجدت
      await _deleteDocumentsByField('ratings', 'rater_user_id', userId);
      await _deleteDocumentsByField('ratings', 'rated_user_id', userId);

      // تحديث متوسط التقييمات للمستخدمين المتأثرين
      await _updateAffectedUsersRatings(userId);

      log('تم حذف جميع التقييمات بنجاح');
    } catch (e) {
      log('خطأ أثناء حذف التقييمات: $e');
    }
  }

  /// حذف subcollection من جميع المستخدمين بناءً على شرط معين
  Future<void> _deleteSubcollectionFromAllUsers(
    String subcollection,
    String field,
    String value,
  ) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final deleteTasks = <Future<void>>[];

      for (final userDoc in usersSnapshot.docs) {
        deleteTasks.add(
          _deleteFromUserSubcollection(userDoc.id, subcollection, field, value),
        );
      }

      await Future.wait(deleteTasks);
    } catch (e) {
      log('خطأ في حذف $subcollection من جميع المستخدمين: $e');
    }
  }

  /// حذف وثائق من subcollection لمستخدم معين
  Future<void> _deleteFromUserSubcollection(
    String userDocId,
    String subcollection,
    String field,
    String value,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userDocId)
              .collection(subcollection)
              .where(field, isEqualTo: value)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        log(
          'تم حذف ${snapshot.docs.length} وثيقة من $subcollection للمستخدم $userDocId',
        );
      }
    } catch (e) {
      log('خطأ في حذف $subcollection للمستخدم $userDocId: $e');
    }
  }

  /// تحديث متوسط التقييمات للمستخدمين المتأثرين
  Future<void> _updateAffectedUsersRatings(String deletedUserId) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final updateTasks = <Future<void>>[];

      for (final userDoc in usersSnapshot.docs) {
        updateTasks.add(_updateUserRatingAverage(userDoc.id));
      }

      await Future.wait(updateTasks);
    } catch (e) {
      log('خطأ في تحديث متوسط التقييمات: $e');
    }
  }

  /// تحديث متوسط التقييم لمستخدم معين
  Future<void> _updateUserRatingAverage(String userId) async {
    try {
      final ratingsSnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('reviews')
              .get();

      int totalReviews = ratingsSnapshot.docs.length;
      double totalRating = 0;

      for (var doc in ratingsSnapshot.docs) {
        final rating = doc.data()['rating'] ?? 0;
        totalRating += (rating as num).toDouble();
      }

      final averageRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;

      await _firestore.collection('users').doc(userId).update({
        'rating': averageRating,
        'reviews': totalReviews,
      });
    } catch (e) {
      log('تم تجاهل خطأ في تحديث متوسط التقييم للمستخدم $userId: $e');
    }
  }

  /// حذف البيانات الشخصية للمستخدم
  Future<void> _deleteUserPersonalData(String userId, String? userEmail) async {
    log('بدء حذف البيانات الشخصية: $userId');

    final collections = [ 'offers', 'products', 'users'];

    final deleteTasks = <Future<void>>[];

    for (final collection in collections) {
      deleteTasks.add(_deleteDocumentsByField(collection, 'user_id', userId));

      // حذف البيانات المرتبطة بالإيميل إن وجد
      if (userEmail != null) {
        deleteTasks.add(
          _deleteDocumentsByField(collection, 'email', userEmail),
        );
      }
    }

    await Future.wait(deleteTasks);
    log('تم حذف البيانات الشخصية بنجاح');
  }

  /// حذف جميع ملفات التخزين الخاصة بالمستخدم
  Future<void> _deleteAllUserStorageFiles(String userId) async {
    log('بدء حذف ملفات التخزين: $userId');

    final storagePaths = [
      'product_images/$userId',
      'profile_images/$userId',
      'offer_images/$userId',
    ];

    final deleteTasks = <Future<void>>[];

    for (final path in storagePaths) {
      deleteTasks.add(_deleteStorageDirectory(path));
    }

    await Future.wait(deleteTasks);
    log('تم حذف جميع ملفات التخزين بنجاح');
  }

  /// حذف مجلد من التخزين
  Future<void> _deleteStorageDirectory(String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      await _deleteStorageRecursively(storageRef);
      log('تم حذف مجلد التخزين: $path');
    } catch (e) {
      log('خطأ في حذف مجلد التخزين $path: $e');
    }
  }

  /// حذف مجلد التخزين بشكل تدريجي
  Future<void> _deleteStorageRecursively(Reference ref) async {
    try {
      final listResult = await ref.listAll();
      final deleteTasks = <Future<void>>[];

      // حذف الملفات المباشرة
      for (final item in listResult.items) {
        deleteTasks.add(
          item.delete().catchError((e) {
            log('خطأ في حذف الملف ${item.fullPath}: $e');
          }),
        );
      }

      // حذف المجلدات الفرعية
      for (final prefix in listResult.prefixes) {
        deleteTasks.add(_deleteStorageRecursively(prefix));
      }

      await Future.wait(deleteTasks);
    } catch (e) {
      log('خطأ في حذف مجلد تدريجي ${ref.fullPath}: $e');
    }
  }

  /// حذف وثيقة المستخدم الرئيسية
  Future<void> _deleteMainUserDocument(String userId) async {
    log('حذف وثيقة المستخدم الرئيسية: $userId');
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .delete()
          .timeout(_operationTimeout);
      log('تم حذف وثيقة المستخدم الرئيسية بنجاح');
    } catch (e) {
      log('خطأ في حذف وثيقة المستخدم الرئيسية: $e');
      rethrow; // نرمي الخطأ هنا لأن حذف الوثيقة الرئيسية مهم
    }
  }

  /// مسح جميع بيانات SharedPreferences
  Future<void> _clearSharedPreferences() async {
    log('بدء مسح SharedPreferences');
    try {
      await Prefs.clearAllUserData();
      log('تم مسح جميع بيانات SharedPreferences بنجاح');
    } catch (e) {
      log('خطأ أثناء مسح SharedPreferences: $e');
    }
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

  /// دالة مساعدة لحذف الوثائق بناءً على حقل معين
  Future<void> _deleteDocumentsByField(
    String collection,
    String field,
    String value, {
    bool hasImages = false,
  }) async {
    try {
      bool hasMore = true;
      int totalDeleted = 0;

      while (hasMore) {
        final snapshot = await _firestore
            .collection(collection)
            .where(field, isEqualTo: value)
            .limit(_batchSize)
            .get()
            .timeout(_operationTimeout);

        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final batch = _firestore.batch();
        final imagesToDelete = <String>[];

        for (final doc in snapshot.docs) {
          if (hasImages) {
            final data = doc.data();
            final imageUrl = data['image_url'] as String?;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              imagesToDelete.add(imageUrl);
            }
          }
          batch.delete(doc.reference);
        }

        await batch.commit().timeout(_operationTimeout);

        if (hasImages && imagesToDelete.isNotEmpty) {
          await _deleteStorageImages(imagesToDelete);
        }

        totalDeleted += snapshot.docs.length;
        log(
          'تم حذف ${snapshot.docs.length} وثيقة من $collection (المجموع: $totalDeleted)',
        );

        if (snapshot.docs.length < _batchSize) {
          hasMore = false;
        }
      }
    } catch (e) {
      log('خطأ في حذف وثائق من $collection: $e');
    }
  }

  /// حذف الصور من التخزين
  Future<void> _deleteStorageImages(List<String> imageUrls) async {
    final deleteTasks = <Future<void>>[];

    for (final imageUrl in imageUrls) {
      deleteTasks.add(
        _storage.refFromURL(imageUrl).delete().catchError((e) {
          log('خطأ في حذف الصورة $imageUrl: $e');
        }),
      );
    }

    await Future.wait(deleteTasks);
  }

  /// التحقق من حالة عملية الحذف (محسنة)
  Future<Map<String, dynamic>> checkDeletionStatus(String userId) async {
    try {
      final results = <String, dynamic>{};

      // التحقق من وجود وثيقة المستخدم
      final userDoc = await _firestore.collection('users').doc(userId).get();
      results['user_document_exists'] = userDoc.exists;

      if (!userDoc.exists) {
        results['message'] = 'تم حذف المستخدم بنجاح';
        return results;
      }

      // التحقق من الـ subcollections
      final subcollections = ['orders', 'farmer_orders', 'reviews'];
      for (final subcollection in subcollections) {
        final snapshot =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection(subcollection)
                .limit(1)
                .get();
        results['has_$subcollection'] = snapshot.docs.isNotEmpty;
      }

      // التحقق من المنتجات
      final productsSnapshot =
          await _firestore
              .collection('products')
              .where('farmer_id', isEqualTo: userId)
              .limit(1)
              .get();
      results['has_products'] = productsSnapshot.docs.isNotEmpty;

      // التحقق من العروض
      final offersSnapshot =
          await _firestore
              .collection('offers')
              .where('farmer_id', isEqualTo: userId)
              .limit(1)
              .get();
      results['has_offers'] = offersSnapshot.docs.isNotEmpty;

      return results;
    } catch (e) {
      log('خطأ في التحقق من حالة الحذف: $e');
      return {'error': e.toString()};
    }
  }

  /// حذف المستخدم من جميع البيانات في users collection (دالة مخصصة)
  Future<void> deleteUserFromUsersCollectionOnly(String userId) async {
    log('بدء حذف المستخدم من users collection فقط: $userId');

    try {
      // حذف جميع الـ subcollections أولاً
      await _deleteAllUserSubCollections(userId);

      // ثم حذف الوثيقة الرئيسية
      await _deleteMainUserDocument(userId);

      log('تم حذف المستخدم من users collection بنجاح');
    } catch (e) {
      log('خطأ في حذف المستخدم من users collection: $e');
      throw CustomException(
        message: 'حدث خطأ أثناء حذف بيانات المستخدم: ${e.toString()}',
      );
    }
  }
}
