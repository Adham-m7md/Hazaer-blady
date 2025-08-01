import 'package:flutter/material.dart';
import 'package:hadaer_blady/core/utils/app_colors.dart';

class CustomLoadingIndicator extends StatelessWidget {
  const CustomLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.kprimaryColor),
          backgroundColor: AppColors.kGrayColor.withAlpha(20),
        ),
      ),
    );
  }
}
