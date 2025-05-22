import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color = AppColors.kprimaryColor,
  });

  final VoidCallback? onPressed; // تغيير إلى VoidCallback? عشان يقبل null
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.screenHeight * 0.06,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: color,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        child: Text(
          text,
          style: TextStyles.bold16.copyWith(color: AppColors.kWiteColor),
        ),
      ),
    );
  }
}

class CustomCartButton extends StatelessWidget {
  const CustomCartButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.itemCount = 0,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final String text;
  final int itemCount; // عدد المنتجات المختارة (اختياري للسلة)
  final bool enabled; // تحديد إذا كان الزر مفعل أم لا

  @override
  Widget build(BuildContext context) {
    final buttonText = itemCount > 0 ? '$text ($itemCount)' : text;

    return SizedBox(
      height: context.screenHeight * 0.06,
      width: double.infinity,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor:
              enabled ? AppColors.kprimaryColor : AppColors.kGrayColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        child: Text(
          buttonText,
          style: TextStyles.bold16.copyWith(color: AppColors.kWiteColor),
        ),
      ),
    );
  }
}