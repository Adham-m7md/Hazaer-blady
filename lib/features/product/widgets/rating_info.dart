import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/features/rateing/view/rating_screen.dart';

class RatingInfo extends StatelessWidget {
  final String rating;
  final int reviews;
  final String userId;

  const RatingInfo({
    super.key,
    required this.rating,
    required this.reviews,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star, color: Color(0xffFFC529), size: 28),
        const SizedBox(width: 8),
        Text(
          rating,
          style: TextStyles.bold16.copyWith(color: AppColors.kBlackColor),
        ),
        const SizedBox(width: 8),
        Text(
          '($reviews)',
          style: TextStyles.semiBold16.copyWith(color: AppColors.kGrayColor),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            if (userId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RatingScreen(userId: userId),
                ),
              );
            } else {
              // عرض رسالة للمستخدم في حالة عدم وجود معرف
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'لا يمكن عرض التقييمات. معرف المستخدم غير متوفر.',
                  ),
                ),
              );
            }
          },
          child: Text(
            'التقييمات',
            style: TextStyles.bold16.copyWith(
              color: AppColors.kprimaryColor,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.kprimaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
