import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // تعديل: استخدام مسار subcollection للتقييمات
  Stream<Map<String, dynamic>> streamUserRatings(String userId) {
    if (userId.isEmpty) {
      return Stream.error('معرف المستخدم غير صالح');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .snapshots()
        .map((snapshot) {
          double totalRating = 0.0;
          int totalReviews = snapshot.docs.length;
          List<Map<String, dynamic>> ratings = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
            ratings.add({
              'rating_id': doc.id,
              'rating': data['rating'] ?? 0,
              'comment': data['comment'] ?? '',
              'rater_user_id': data['rater_user_id'] ?? '',
              'rater_name': data['rater_name'] ?? 'مستخدم',
            });
          }

          final averageRating =
              totalReviews > 0 ? totalRating / totalReviews : 0.0;

          return {
            'averageRating': averageRating,
            'totalReviews': totalReviews,
            'ratings': ratings,
          };
        });
  }

  Future<void> _checkAuthorization() async {
    // التحقق من وجود مستخدم
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // تحقق من اتصال المستخدم (اختياري يمكن استخدام مكتبة connectivity)
    try {
      await _firestore.collection('users').limit(1).get();
    } catch (e) {
      throw Exception('فشل الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت');
    }
  }

  // تعديل: جلب تقييمات المستخدم من subcollection
  Future<Map<String, dynamic>> fetchUserRatings(String userId) async {
    try {
      await _checkAuthorization();

      // الحصول على مجموعة التقييمات للمستخدم المحدد من الـ subcollection
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('reviews')
          .get();

      if (snapshot.docs.isEmpty) {
        return {'averageRating': 0.0, 'totalReviews': 0, 'ratings': []};
      }

      // تحويل البيانات واحتساب متوسط التقييم
      final List<Map<String, dynamic>> ratings = [];
      double totalRating = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['rating_id'] = doc.id; // إضافة معرف التقييم
        ratings.add(data);
        totalRating += (data['rating'] as num).toDouble();
      }

      final double avgRating = totalRating / ratings.length;

      // تصنيف التقييمات بحيث يظهر تقييم المستخدم الحالي أولاً ثم الباقي بترتيب تنازلي
      ratings.sort((a, b) {
        // إذا كان أحدهما للمستخدم الحالي، يأتي أولاً
        final currentUserId = _auth.currentUser?.uid;
        final aIsCurrentUser = a['rater_user_id'] == currentUserId;
        final bIsCurrentUser = b['rater_user_id'] == currentUserId;

        if (aIsCurrentUser && !bIsCurrentUser) return -1;
        if (!aIsCurrentUser && bIsCurrentUser) return 1;

        // ترتيب الآخرين حسب الأحدث
        final aTimestamp = a['timestamp'] as Timestamp?;
        final bTimestamp = b['timestamp'] as Timestamp?;

        if (aTimestamp != null && bTimestamp != null) {
          return bTimestamp.compareTo(
            aTimestamp,
          ); // ترتيب تنازلي (الأحدث أولاً)
        }

        return 0;
      });

      return {
        'averageRating': avgRating,
        'totalReviews': ratings.length,
        'ratings': ratings,
      };
    } catch (e) {
      log('Error in fetchUserRatings: $e');
      throw Exception('فشل في جلب التقييمات: ${e.toString()}');
    }
  }

  // تعديل: إضافة تقييم جديد إلى subcollection
  Future<void> submitRating({
    required String ratedUserId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _checkAuthorization();

      final currentUser = _auth.currentUser!;
      final currentUserId = currentUser.uid;

      // لا يمكن للمستخدم تقييم نفسه
      if (currentUserId == ratedUserId) {
        throw Exception('لا يمكنك تقييم نفسك');
      }

      // التحقق من وجود تقييم سابق من نفس المستخدم
      final existingRating = await _firestore
          .collection('users')
          .doc(ratedUserId)
          .collection('reviews')
          .where('rater_user_id', isEqualTo: currentUserId)
          .get();

      if (existingRating.docs.isNotEmpty) {
        // إذا كان هناك تقييم سابق، قم بتحديثه بدلاً من إنشاء واحد جديد
        final ratingId = existingRating.docs.first.id;
        return await updateRating(
          ratedUserId: ratedUserId,
          ratingId: ratingId,
          rating: rating,
          comment: comment,
        );
      }

      // الحصول على اسم المستخدم الحالي
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data();

      if (userData == null) {
        throw Exception('لم يتم العثور على بيانات المستخدم');
      }

      String raterName = userData['name'] ?? userData['username'] ?? 'مستخدم';

      // إضافة التقييم الجديد في الـ subcollection
      await _firestore
          .collection('users')
          .doc(ratedUserId)
          .collection('reviews')
          .add({
            'rater_user_id': currentUserId,
            'rater_name': raterName,
            'rating': rating,
            'comment': comment,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // تحديث متوسط التقييم في وثيقة المستخدم الرئيسية
      await _updateUserRatingAverage(ratedUserId);
      
    } catch (e) {
      log('Error in submitRating: $e');
      throw Exception('فشل إضافة التقييم: ${e.toString()}');
    }
  }

  // تعديل: تحديث تقييم موجود في subcollection
  Future<void> updateRating({
    required String ratedUserId,
    required String ratingId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _checkAuthorization();

      final currentUser = _auth.currentUser!;
      final currentUserId = currentUser.uid;

      // التحقق من أن التقييم موجود وينتمي للمستخدم الحالي
      final ratingDoc = await _firestore
          .collection('users')
          .doc(ratedUserId)
          .collection('reviews')
          .doc(ratingId)
          .get();

      if (!ratingDoc.exists) {
        throw Exception('لم يتم العثور على التقييم');
      }

      final ratingData = ratingDoc.data()!;

      if (ratingData['rater_user_id'] != currentUserId) {
        throw Exception('ليس لديك صلاحية لتعديل هذا التقييم');
      }

      // تحديث التقييم
      await _firestore
          .collection('users')
          .doc(ratedUserId)
          .collection('reviews')
          .doc(ratingId)
          .update({
            'rating': rating,
            'comment': comment,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // تحديث متوسط التقييم في وثيقة المستخدم الرئيسية
      await _updateUserRatingAverage(ratedUserId);
      
    } catch (e) {
      log('Error in updateRating: $e');
      throw Exception('فشل تحديث التقييم: ${e.toString()}');
    }
  }

  // تعديل: حذف تقييم من subcollection
  Future<void> deleteRating(String ratingId, {required String ratedUserId}) async {
    try {
      await _checkAuthorization();

      final currentUser = _auth.currentUser!;
      final currentUserId = currentUser.uid;

      // التحقق من أن التقييم موجود وينتمي للمستخدم الحالي
      final ratingDoc = await _firestore
          .collection('users')
          .doc(ratedUserId)
          .collection('reviews')
          .doc(ratingId)
          .get();

      if (!ratingDoc.exists) {
        throw Exception('لم يتم العثور على التقييم');
      }

      final ratingData = ratingDoc.data()!;

      if (ratingData['rater_user_id'] != currentUserId) {
        throw Exception('ليس لديك صلاحية لحذف هذا التقييم');
      }

      // حذف التقييم
      await _firestore
          .collection('users')
          .doc(ratedUserId)
          .collection('reviews')
          .doc(ratingId)
          .delete();

      // تحديث متوسط التقييم في وثيقة المستخدم الرئيسية
      await _updateUserRatingAverage(ratedUserId);
      
    } catch (e) {
      log('Error in deleteRating: $e');
      throw Exception('فشل حذف التقييم: ${e.toString()}');
    }
  }
  
  // دالة جديدة: تحديث متوسط التقييم في وثيقة المستخدم الرئيسية
  Future<void> _updateUserRatingAverage(String userId) async {
    try {
      // جلب جميع التقييمات للمستخدم
      final ratingsSnapshot = await _firestore
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
      
      // حساب المتوسط
      final averageRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;
      
      // تحديث وثيقة المستخدم بالمتوسط الجديد وعدد التقييمات
      await _firestore.collection('users').doc(userId).update({
        'rating': averageRating,
        'reviews': totalReviews,
      });
      
    } catch (e) {
      log('Error updating user rating average: $e');
      // لا نريد أن نفشل العملية الرئيسية إذا فشل تحديث المتوسط
    }
  }
  
  // دالة جديدة: ترحيل البيانات من التجميع القديم إلى الجديد
  Future<void> migrateRatingsToSubcollections() async {
    try {
      // جلب جميع التقييمات من المجموعة القديمة
      final oldRatingsSnapshot = await _firestore.collection('ratings').get();
      
      // مجموعة لتخزين معرفات المستخدمين الذين تم ترحيل تقييماتهم
      final Set<String> updatedUsers = {};
      
      // ترحيل كل تقييم إلى subcollection الخاصة بالمستخدم المقيم
      for (var doc in oldRatingsSnapshot.docs) {
        final data = doc.data();
        final ratedUserId = data['rated_user_id'];
        
        if (ratedUserId != null && ratedUserId.isNotEmpty) {
          // إضافة التقييم إلى subcollection
          await _firestore
              .collection('users')
              .doc(ratedUserId)
              .collection('reviews')
              .doc(doc.id) // استخدام نفس معرف الوثيقة
              .set(data);
          
          // إضافة معرف المستخدم إلى المجموعة للتحديث لاحقًا
          updatedUsers.add(ratedUserId);
        }
      }
      
      // تحديث متوسط التقييمات لكل مستخدم تم ترحيل تقييماته
      for (var userId in updatedUsers) {
        await _updateUserRatingAverage(userId);
      }
      
      log('تم ترحيل ${oldRatingsSnapshot.docs.length} تقييم إلى subcollections');
      
    } catch (e) {
      log('Error in migrateRatingsToSubcollections: $e');
      throw Exception('فشل ترحيل التقييمات: ${e.toString()}');
    }
  }
  
  // ترحيل البيانات لمستخدم معين فقط
  Future<void> migrateUserRatings(String userId) async {
    try {
      // جلب تقييمات المستخدم المحدد من المجموعة القديمة
      final oldRatingsSnapshot = await _firestore
          .collection('ratings')
          .where('rated_user_id', isEqualTo: userId)
          .get();
      
      // ترحيل كل تقييم إلى subcollection
      for (var doc in oldRatingsSnapshot.docs) {
        final data = doc.data();
        
        // إضافة التقييم إلى subcollection
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('reviews')
            .doc(doc.id) // استخدام نفس معرف الوثيقة
            .set(data);
      }
      
      // تحديث متوسط التقييم
      await _updateUserRatingAverage(userId);
      
      log('تم ترحيل ${oldRatingsSnapshot.docs.length} تقييم للمستخدم $userId');
      
    } catch (e) {
      log('Error in migrateUserRatings: $e');
      throw Exception('فشل ترحيل تقييمات المستخدم: ${e.toString()}');
    }
  }
}