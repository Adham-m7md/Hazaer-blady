abstract class RatingState {}

// حالة التحميل
class RatingLoadingState extends RatingState {}

// حالة النجاح مع بيانات التقييمات
class RatingSuccessState extends RatingState {
  final double averageRating;
  final int totalReviews;
  final List<Map<String, dynamic>> ratings;

  RatingSuccessState({
    required this.averageRating,
    required this.totalReviews,
    required this.ratings,
  });
}

// حالة الخطأ
class RatingErrorState extends RatingState {
  final String message;

  RatingErrorState(this.message);
}

// حالة نجاح إضافة أو تحديث أو حذف تقييم
class RatingActionSuccessState extends RatingState {
  final String message;

  RatingActionSuccessState(this.message);
}
