import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_directions.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class AddProductButton extends StatelessWidget {
  const AddProductButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color = AppColors.kprimaryColor,
  });

  final VoidCallback? onPressed;
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
