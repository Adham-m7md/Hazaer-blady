import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  });
  final String text, buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.kWiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Center(
        child: Column(
          spacing: 36,
          children: [
            SvgPicture.asset(Assets.imagesCongrates),

            Text(
              text,
              style: TextStyles.semiBold16,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            CustomButton(onPressed: () => onPressed(), text: buttonText),
          ],
        ),
      ),
    );
  }
}
