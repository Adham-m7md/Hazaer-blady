import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';
import 'package:hadaer_blady/core/utils/svg_images.dart';
import 'package:hadaer_blady/core/widgets/custom_button.dart';

class CustomeShowDialog extends StatelessWidget {
  const CustomeShowDialog({
    super.key,
    required this.text,
    required this.buttonText,
    required this.onPressed,
    this.imagePath = Assets.imagesCongrates,
  });

  final String text;
  final String buttonText;
  final VoidCallback onPressed;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.kWiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Center(
        child: Column(
          spacing: 36,
          children: [
            SvgPicture.asset(
              imagePath,
              width:
                  imagePath != Assets.imagesCongrates
                      ? 100
                      : 120, // حجم أصغر لغير التهنئة
              height:
                  imagePath != Assets.imagesCongrates
                      ? 100
                      : 120, // حجم أكبر للتهنئة
            ),
            Text(
              text,
              style: TextStyles.semiBold16,
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
            CustomButton(onPressed: onPressed, text: buttonText),
          ],
        ),
      ),
    );
  }
}
