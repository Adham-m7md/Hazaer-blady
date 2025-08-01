import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hadaer_blady/core/functions/build_app_bar_with_arrow_back_button.dart';
import 'package:hadaer_blady/core/services/rating_service.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';
import 'package:hadaer_blady/core/widgets/custom_loading_indicator.dart';
import 'package:hadaer_blady/core/widgets/custom_text_form_feild.dart';
import 'package:hadaer_blady/features/auth/presentation/signin/view/signin_screen.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_cubit.dart';
import 'package:hadaer_blady/features/rateing/cubit/rating_state.dart';

class RatingScreen extends StatelessWidget {
  const RatingScreen({super.key, required this.userId});
  static const String id = 'ratingScreen';
  final String userId;

  @override
  Widget build(BuildContext context) {
    // التحقق من وجود مستخدم مسجل الدخول
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, SigninScreen.id);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // التحقق من صلاحية معرف المستخدم
    if (userId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.kWiteColor,
        appBar: buildAppBarWithArrowBackButton(
          title: 'التقييمات',
          context: context,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'معرف المستخدم غير صالح',
                style: TextStyles.semiBold16.copyWith(
                  color: AppColors.kRedColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () => Navigator.pop(context),
                text: 'العودة',
              ),
            ],
          ),
        ),
      );
    }

    // جلب اسم المستخدم باستخدام FutureBuilder
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String title = 'التقييمات';
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final userName =
                userData?['name'] ?? userData?['displayName'] ?? 'مستخدم';
            title = 'تقييمات - $userName';
          } else if (snapshot.hasError) {
            log(
              'Error fetching user data for userId $userId: ${snapshot.error}',
            );
          }
        }

        return BlocProvider(
          create:
              (context) => RatingCubit(
                ratingService: RatingService(),
                auth: FirebaseAuth.instance,
                userId: userId,
              ),
          child: _RatingScreenContent(title: title),
        );
      },
    );
  }
}

class _RatingScreenContent extends StatelessWidget {
  const _RatingScreenContent({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RatingCubit, RatingState>(
      listener: (context, state) {
        if (state is RatingActionSuccessState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is RatingErrorState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.kWiteColor,
          appBar: buildAppBarWithArrowBackButton(
            title: title,
            context: context,
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, RatingState state) {
    final cubit = context.read<RatingCubit>();

    if (state is RatingLoadingState) {
      return const Center(child: CustomLoadingIndicator());
    } else if (state is RatingErrorState &&
        state is! RatingActionSuccessState) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.message,
              style: TextStyles.semiBold16.copyWith(color: AppColors.kRedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: () async => cubit.refreshRatings(),
              text: 'إعادة المحاولة',
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                backgroundColor: AppColors.kWiteColor,
                color: AppColors.kprimaryColor,
                onRefresh: () async => cubit.refreshRatings(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildRatingSummary(cubit),
                      const SizedBox(height: 16),
                      _buildRatingProgressBars(cubit),
                      const SizedBox(height: 16),
                      _buildReviewCount(cubit),
                      const SizedBox(height: 16),
                      _buildRatingsList(context, cubit),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
            CustomButton(
              onPressed: () => _showRatingDialog(context),
              text: 'أضف تقييم',
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRatingSummary(RatingCubit cubit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Flexible(
          child: Text(
            'الملخص',
            style: TextStyles.semiBold19,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(cubit.averageRating.toStringAsFixed(1), style: TextStyles.bold19),
        const SizedBox(width: 8),
        const Icon(Icons.star, color: AppColors.kYellowColor, size: 24),
      ],
    );
  }

  Widget _buildRatingProgressBars(RatingCubit cubit) {
    return Column(
      children: List.generate(5, (index) {
        final star = 5 - index;
        final progress =
            cubit.ratings.where((r) => r['rating'] == star).length /
            (cubit.totalReviews == 0 ? 1 : cubit.totalReviews);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text('$star', style: TextStyles.bold16),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 13,
                  backgroundColor: AppColors.kFillGrayColor,
                  color: AppColors.kYellowColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReviewCount(RatingCubit cubit) {
    return Row(
      children: [
        const Flexible(
          child: Text(
            'عدد المراجعات :',
            style: TextStyles.semiBold19,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text('${cubit.totalReviews}', style: TextStyles.semiBold19),
      ],
    );
  }

  Widget _buildRatingsList(BuildContext context, RatingCubit cubit) {
    final currentUserId = cubit.currentUserId;
    if (cubit.ratings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'لا توجد مراجعات حتى الآن. كن أول من يقيم!',
            style: TextStyles.regular16,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children:
          cubit.ratings.map((rating) {
            final isCurrentUserRating =
                currentUserId != null &&
                rating['rater_user_id'] == currentUserId;
            final name = rating['rater_name'] ?? 'مستخدم';
            final ratingValue = rating['rating'] ?? 0;
            final comment = rating['comment'] ?? '';
            final raterUserId = rating['rater_user_id'] ?? '';
            final ratingId = rating['rating_id'] ?? '';
            return SomeOneRate(
              name: name,
              rating: ratingValue,
              comment: comment,
              raterUserId: raterUserId,
              ratingId: ratingId,
              onEdit:
                  isCurrentUserRating
                      ? () => _showEditRatingDialog(context, rating)
                      : null,
              onDelete:
                  isCurrentUserRating
                      ? () => _showDeleteConfirmDialog(context, ratingId)
                      : null,
            );
          }).toList(),
    );
  }

  void _showRatingDialog(BuildContext context) {
    final cubit = context.read<RatingCubit>();
    showDialog(
      context: context,
      builder: (context) {
        int selectedRating = 0;
        final commentController = TextEditingController();
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          backgroundColor: AppColors.kWiteColor,
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('أضف تقييم', style: TextStyles.bold19),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                          icon: Icon(
                            Icons.star,
                            color:
                                index < selectedRating
                                    ? AppColors.kYellowColor
                                    : AppColors.kGrayColor,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    CustomTextFormFeild(
                      hintText: 'أضف تجربتك',
                      controller: commentController,
                      keyBoardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال تعليق';
                        }
                        if (value.length > 500) {
                          return 'التعليق طويل جدًا (الحد الأقصى 500 حرف)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomRatingButton(
                          onPressed: () async {
                            if (selectedRating == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('يرجى اختيار تقييم'),
                                ),
                              );
                              return;
                            }
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            Navigator.pop(context);
                            cubit.submitRating(
                              rating: selectedRating,
                              comment: commentController.text.trim(),
                            );
                          },
                          text: 'حفظ',
                        ),
                        CustomRatingButton(
                          onPressed: () => Navigator.pop(context),
                          text: 'إلغاء',
                          color: AppColors.kRedColor,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showEditRatingDialog(
    BuildContext context,
    Map<String, dynamic> rating,
  ) {
    final cubit = context.read<RatingCubit>();
    final ratingId = rating['rating_id'];
    if (ratingId == null || ratingId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('معرف التقييم غير صالح')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        int selectedRating = rating['rating'] ?? 0;
        final commentController = TextEditingController(
          text: rating['comment'] ?? '',
        );
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          backgroundColor: AppColors.kWiteColor,
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('تعديل تقييم', style: TextStyles.bold19),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                          icon: Icon(
                            Icons.star,
                            color:
                                index < selectedRating
                                    ? AppColors.kYellowColor
                                    : AppColors.kGrayColor,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    CustomTextFormFeild(
                      hintText: 'أضف تجربتك',
                      controller: commentController,
                      keyBoardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال تعليق';
                        }
                        if (value.length > 500) {
                          return 'التعليق طويل جدًا (الحد الأقصى 500 حرف)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomRatingButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            Navigator.pop(context);
                            cubit.updateRating(
                              ratingId: ratingId,
                              rating: selectedRating,
                              comment: commentController.text.trim(),
                            );
                          },
                          text: 'حفظ',
                        ),
                        CustomRatingButton(
                          onPressed: () => Navigator.pop(context),
                          text: 'إلغاء',
                          color: AppColors.kRedColor,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String ratingId) {
    final cubit = context.read<RatingCubit>();
    if (ratingId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('معرف التقييم غير صالح')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.kWiteColor,
          title: const Text('حذف التقييم', style: TextStyles.bold19),
          content: const Text(
            'هل أنت متأكد من رغبتك في حذف هذا التقييم؟',
            style: TextStyles.regular16,
          ),
          actions: [
            CustomRatingButton(
              onPressed: () {
                Navigator.pop(context);
                cubit.deleteRating(ratingId);
              },
              text: 'حذف',
              color: AppColors.kRedColor,
            ),
            CustomRatingButton(
              onPressed: () => Navigator.pop(context),
              text: 'إلغاء',
            ),
          ],
        );
      },
    );
  }
}

class CustomRatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color color;

  const CustomRatingButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color = AppColors.kprimaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.kWiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(text, style: TextStyles.regular16),
    );
  }
}

class SomeOneRate extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;
  final String raterUserId;
  final String ratingId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SomeOneRate({
    super.key,
    required this.name,
    required this.rating,
    required this.comment,
    required this.raterUserId,
    required this.ratingId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kFillGrayColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyles.semiBold16,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          color:
                              index < rating
                                  ? AppColors.kYellowColor
                                  : AppColors.kGrayColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null && onDelete != null)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: AppColors.kprimaryColor,
                      ),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: AppColors.kRedColor,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: TextStyles.regular16),
        ],
      ),
    );
  }
}
