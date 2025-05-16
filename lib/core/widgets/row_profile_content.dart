import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';
import 'package:hadaer_blady/core/utils/app_text_styles.dart';

class CustomeRowProfileContent extends StatelessWidget {
  const CustomeRowProfileContent({
    super.key,
    this.secondIcon = Icons.arrow_forward_ios_outlined,
    required this.titelText,

    required this.icon,
    this.actionButton,
  });
  final IconData icon;
  final IconData? secondIcon;
  final String titelText;
  final VoidCallback? actionButton;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Text(
          titelText,
          style: TextStyles.semiBold16.copyWith(color: AppColors.kGrayColor),
        ),
        Spacer(),
        IconButton(
          onPressed: actionButton,
          icon: Icon(secondIcon, color: AppColors.kprimaryColor),
        ),
      ],
    );
  }
}
