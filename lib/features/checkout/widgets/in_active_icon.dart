import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class InActiveStepIcon extends StatelessWidget {
  const InActiveStepIcon({super.key, required this.index, required this.text});
  final String index, text;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 12.5,
          backgroundColor: AppColors.kFillGrayColor,
          child: Text(index, style: TextStyles.bold16),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyles.semiBold16.copyWith(color: AppColors.kGrayColor),
        ),
      ],
    );
  }
}
