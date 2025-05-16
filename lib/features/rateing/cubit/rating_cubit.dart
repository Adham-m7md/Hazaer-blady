import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_state.dart';

class RatingCubit extends Cubit<RatingState> {
  final RatingService _ratingService;
  final FirebaseAuth _auth;
  final String userId;
  StreamSubscription? _ratingSubscription;

  // بيانات مخزنة للرجوع إليها
  double _averageRating = 0.0;
  int _totalReviews = 0;
  List<Map<String, dynamic>> _ratings = [];

  RatingCubit({
    required RatingService ratingService,
    required FirebaseAuth auth,
    required this.userId,
  }) : _ratingService = ratingService,
       _auth = auth,
       super(RatingLoadingState()) {
    log('RatingCubit created with userId: $userId');
    if (userId.isNotEmpty) {
      _listenToRatings();
    } else {
      emit(RatingErrorState('معرف المستخدم غير صالح'));
    }
  }

  // الاستماع إلى Stream التقييمات
  void _listenToRatings() {
    emit(RatingLoadingState());
    _ratingSubscription?.cancel(); // إلغاء أي اشتراك سابق
    _ratingSubscription = _ratingService
        .streamUserRatings(userId)
        .listen(
          (data) {
            _averageRating = data['averageRating'];
            _totalReviews = data['totalReviews'];
            _ratings = List<Map<String, dynamic>>.from(data['ratings']);

            emit(
              RatingSuccessState(
                averageRating: _averageRating,
                totalReviews: _totalReviews,
                ratings: _ratings,
              ),
            );
          },
          onError: (e) {
            log('Error streaming ratings: $e');
            emit(
              RatingErrorState(e.toString().replaceFirst('Exception: ', '')),
            );
          },
        );
  }

  // إعادة تحميل التقييمات يدويًا
  void refreshRatings() {
    _listenToRatings();
  }

  // الحصول على معرف المستخدم الحالي
  String? get currentUserId => _auth.currentUser?.uid;

  // التحقق من تسجيل الدخول
  bool get isAuthenticated => _auth.currentUser != null;

  // الحصول على البيانات المخزنة
  double get averageRating => _averageRating;
  int get totalReviews => _totalReviews;
  List<Map<String, dynamic>> get ratings => _ratings;

  // إضافة تقييم جديد
  Future<void> submitRating({
    required int rating,
    required String comment,
  }) async {
    if (userId.isEmpty) {
      emit(RatingErrorState('معرف المستخدم غير صالح'));
      return;
    }

    try {
      await _ratingService.submitRating(
        ratedUserId: userId,
        rating: rating,
        comment: comment,
      );
      emit(RatingActionSuccessState('تم إضافة التقييم بنجاح'));
    } catch (e) {
      log('Error submitting rating: $e');
      emit(RatingErrorState(e.toString().replaceFirst('Exception: ', '')));
      emit(
        RatingSuccessState(
          averageRating: _averageRating,
          totalReviews: _totalReviews,
          ratings: _ratings,
        ),
      );
    }
  }

  // تحديث تقييم موجود
  Future<void> updateRating({
    required String ratingId,
    required int rating,
    required String comment,
  }) async {
    if (ratingId.isEmpty) {
      emit(RatingErrorState('معرف التقييم غير صالح'));
      return;
    }

    try {
      await _ratingService.updateRating(
        ratedUserId: userId, // إضافة معرف المستخدم المقيم
        ratingId: ratingId,
        rating: rating,
        comment: comment,
      );
      emit(RatingActionSuccessState('تم تحديث التقييم بنجاح'));
    } catch (e) {
      log('Error updating rating: $e');
      emit(RatingErrorState(e.toString().replaceFirst('Exception: ', '')));
      emit(
        RatingSuccessState(
          averageRating: _averageRating,
          totalReviews: _totalReviews,
          ratings: _ratings,
        ),
      );
    }
  }

  // حذف تقييم
  Future<void> deleteRating(String ratingId) async {
    if (ratingId.isEmpty) {
      emit(RatingErrorState('معرف التقييم غير صالح'));
      return;
    }

    try {
      await _ratingService.deleteRating(
        ratingId,
        ratedUserId: userId, // إضافة معرف المستخدم المقيم
      );
      emit(RatingActionSuccessState('تم حذف التقييم بنجاح'));
    } catch (e) {
      log('Error deleting rating: $e');
      emit(RatingErrorState(e.toString().replaceFirst('Exception: ', '')));
      emit(
        RatingSuccessState(
          averageRating: _averageRating,
          totalReviews: _totalReviews,
          ratings: _ratings,
        ),
      );
    }
  }
  
  // دالة جديدة لترحيل التقييمات لمستخدم معين
  Future<void> migrateUserRatings() async {
    try {
      emit(RatingLoadingState());
      await _ratingService.migrateUserRatings(userId);
      _listenToRatings(); // إعادة تحميل البيانات بعد الترحيل
      emit(RatingActionSuccessState('تم ترحيل التقييمات بنجاح'));
    } catch (e) {
      log('Error migrating ratings: $e');
      emit(RatingErrorState(e.toString().replaceFirst('Exception: ', '')));
      _listenToRatings(); // إعادة محاولة تحميل البيانات حتى في حالة الفشل
    }
  }

  // إلغاء الاشتراك عند إغلاق الكيوبت
  @override
  Future<void> close() {
    _ratingSubscription?.cancel();
    return super.close();
  }
}