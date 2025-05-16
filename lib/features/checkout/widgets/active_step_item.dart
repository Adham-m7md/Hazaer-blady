// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class ActiveStepItem extends StatelessWidget {
  const ActiveStepItem({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 12.5,
          backgroundColor: AppColors.kprimaryColor,
          child: Icon(Icons.check, color: AppColors.kWiteColor, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyles.bold16.copyWith(color: AppColors.kprimaryColor),
        ),
      ],
    );
  }
}
